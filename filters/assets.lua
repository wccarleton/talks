-- Resolve Markdown image sources before Quarto processes figures.
-- Hosted images remain URLs by default. In export mode, hosted images are
-- downloaded into Pandoc's media bag so offline HTML/PPTX writers can embed them.
-- Local files enter Pandoc's media bag so Quarto packages them with HTML and
-- Pandoc embeds them in office-format exports.
local base
local export_remote = false
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

local function truthy(value)
  if not value then return false end
  value = pandoc.utils.stringify(value):lower()
  return value == 'true' or value == '1' or value == 'yes'
end

local function remote_image(url)
  if resolved[url] then return resolved[url] end
  local ok, contents = pcall(pandoc.pipe, 'curl',
    {'--location', '--fail', '--silent', '--show-error', url}, '')
  assert(ok, 'Cannot download image "' .. url .. '": ' .. tostring(contents))
  local clean_url = url:gsub('[?#].*$', '')
  local extension = (clean_url:match('%.([%w]+)$') or ''):lower()
  assert(extension ~= '', 'Remote image needs a file extension: ' .. url)
  local mime = mime_types[extension]
  assert(mime, 'Unsupported remote image extension: ' .. url)
  local name = 'asset-' .. pandoc.utils.sha1(contents) .. '.' .. extension
  pandoc.mediabag.insert(name, mime, contents)
  resolved[url] = name
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
  elseif source:match('^https?://') then
    if not export_remote then return nil end
  elseif source:match('^data:') then
    return nil
  elseif not absolute(source) then
    return nil -- Ordinary deck-relative paths retain Quarto's normal behavior.
  end

  if source:match('^https?://') then
    if export_remote then
      el.src = remote_image(source)
    else
      el.src = source:gsub(' ', '%%20')
    end
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
      export_remote = truthy(os.getenv('TALKS_EXPORT_REMOTE_IMAGES')) or
        truthy(meta['export-remote-images'])
    end },
  { Image = image },
}
