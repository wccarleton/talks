-- Resolve Markdown image sources before Quarto processes figures.
-- Hosted images remain URLs; local files enter Pandoc's media bag so Quarto
-- packages them with HTML and Pandoc embeds them in office-format exports.
local base
local resolved = {}
local script = PANDOC_SCRIPT_FILE
if not script:match('^%a:[/\\]') and not script:match('^[/\\]') then
  script = pandoc.path.join({pandoc.system.get_working_directory(), script})
end
local repository = pandoc.path.directory(pandoc.path.directory(pandoc.path.normalize(script)))

local function absolute(path)
  return path:match('^%a:[/\\]') or path:match('^[/\\]')
end

local function decode(path)
  return (path:gsub('%%(%x%x)', function(hex)
    return string.char(tonumber(hex, 16))
  end))
end

local mime_types = {
  png = 'image/png', jpg = 'image/jpeg', jpeg = 'image/jpeg',
  gif = 'image/gif', svg = 'image/svg+xml', webp = 'image/webp',
  tif = 'image/tiff', tiff = 'image/tiff', avif = 'image/avif',
  pdf = 'application/pdf',
}

local function local_image(path)
  path = decode(path):gsub('\\', '/')
  if resolved[path] then return resolved[path] end
  local file, reason = io.open(path, 'rb')
  assert(file, 'Cannot read image "' .. path .. '": ' .. tostring(reason))
  local contents = file:read('*a')
  file:close()
  local extension = (path:match('%.([%w]+)$') or ''):lower()
  local mime = mime_types[extension]
  assert(mime, 'Unsupported local image extension: ' .. path)
  local name = 'asset-' .. pandoc.utils.sha1(contents) .. '.' .. extension
  pandoc.mediabag.insert(name, mime, contents)
  resolved[path] = name
  return name
end

local function image(el)
  local source = el.src
  if source:match('^assets:') then
    assert(base and base ~= '',
      'Image "' .. source .. '" needs assets-base metadata or TALKS_ASSETS_BASE.')
    local key = source:sub(8):gsub('^/+', '')
    assert(key ~= '', 'An assets: image needs a file path.')
    source = base:gsub('[/\\]+$', '') .. '/' .. key
    if not source:match('^https?://') and not absolute(source) then
      source = pandoc.path.join({repository, source})
    end
  elseif source:match('^https?://') or source:match('^data:') then
    return nil
  elseif not absolute(source) then
    return nil -- Ordinary deck-relative paths retain Quarto's normal behavior.
  end

  if source:match('^https?://') then
    el.src = source:gsub(' ', '%%20')
  else
    el.src = local_image(source)
  end
  return el
end

return {
  { Meta = function(meta)
      base = os.getenv('TALKS_ASSETS_BASE')
      if not base or base == '' then
        base = meta['assets-base'] and pandoc.utils.stringify(meta['assets-base'])
      end
    end },
  { Image = image },
}
