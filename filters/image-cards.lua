-- Keep photo cards as figures so their captions share the frame.
-- Must run before Quarto's Reveal image-stretch transformation.
return {
  Image = function(image)
    if FORMAT ~= 'revealjs' or not image.classes:includes('img-card') then
      return nil
    end
    -- Explicit stretch also splits the figure; .img-card owns this layout.
    image.classes = image.classes:filter(function(class)
      return class ~= 'stretch' and class ~= 'r-stretch'
    end)
    if not image.classes:includes('nostretch') then
      image.classes:insert('nostretch')
    end
    return image
  end
}
