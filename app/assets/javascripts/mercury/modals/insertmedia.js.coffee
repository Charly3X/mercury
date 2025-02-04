@Mercury.modalHandlers.insertMedia = {

  initialize: ->
    @element.find('.control-label input').on('click', @onLabelChecked)
    @element.find('.controls .optional, .controls .required').on('focus', (event) => @onInputFocused($(event.target)))

    @focus('#media_image_url')
    @initializeForm()

    # build the image or embed/iframe on form submission
    @element.find('form').on 'submit', (event) =>
      event.preventDefault()
      @validateForm()
      unless @valid
        @resize()
        return
      @submitForm()
      @hide()


  initializeForm: ->
    # get the selection and initialize its information into the form
    return unless Mercury.region && Mercury.region.selection
    selection = Mercury.region.selection()
    console.log('selection')
    # if we're editing an image prefill the information
    if image = selection.is?('img')
      @element.find('#media_image_url').val(image.attr('src'))
      @element.find('#media_image_alignment').val(image.attr('align'))
      @element.find('#media_image_float').val(if image.attr('style')? then image.css('float') else '')
      @element.find('#media_image_width').val(image.width() || '')
      @element.find('#media_image_height').val(image.height() || '')
      @element.find('#media_image_alt').val(image.attr('alt') || '')
      @focus('#media_image_url')

    if image = selection.is?('audio')
      @element.find('#media_audio_url').val(image.attr('src'))
      @focus('#media_audio_url')

    # if we're editing an iframe (assume it's a video for now)
    if iframe = selection.is?('iframe')
      src = iframe.attr('src')
      if /^https?:\/\/www.youtube.com\//i.test(src)
        # it's a youtube video
        @element.find('#media_youtube_url').val("#{src.match(/^https?/)[0]}://youtu.be/#{src.match(/\/embed\/(\w+)/)[1]}")
        @element.find('#media_youtube_width').val(iframe.width())
        @element.find('#media_youtube_height').val(iframe.height())
        @focus('#media_youtube_url')
      else if /^https?:\/\/player.vimeo.com\//i.test(src)
        # it's a vimeo video
        @element.find('#media_vimeo_url').val("#{src.match(/^https?/)[0]}://vimeo.com/#{src.match(/\/video\/(\w+)/)[1]}")
        @element.find('#media_vimeo_width').val(iframe.width())
        @element.find('#media_vimeo_height').val(iframe.height())
        @focus('#media_vimeo_url')


  focus: (selector) ->
    setTimeout((=> @element.find(selector).focus()), 300)


  onLabelChecked: ->
    forInput = jQuery(@).closest('.control-label').attr('for')
    jQuery(@).closest('.control-group').find("##{forInput}").focus()


  onInputFocused: (input) ->
    input.closest('.control-group').find('input[type=radio]').prop('checked', true)

    return if input.closest('.media-options').length
    @element.find(".media-options").hide()
    @element.find("##{input.attr('id').replace('media_', '')}_options").show()
    @resize(true)


  addInputError: (input, message) ->
    input.after('<span class="help-inline error-message">' + Mercury.I18n(message) + '</span>').closest('.control-group').addClass('error')
    @valid = false


  clearInputErrors: ->
    @element.find('.control-group.error').removeClass('error').find('.error-message').remove()
    @valid = true


  validateForm: ->
    @clearInputErrors()

    type = @element.find('input[name=media_type]:checked').val()
    el = @element.find("#media_#{type}")

    switch type
      when 'youtube_url'
        url = @element.find('#media_youtube_url').val()
        @addInputError(el, "is invalid") unless /^https?:\/\/youtu.be\//.test(url)
      when 'vimeo_url'
        url = @element.find('#media_vimeo_url').val()
        @addInputError(el, "is invalid") unless /^https?:\/\/vimeo.com\//.test(url)
      else
        @addInputError(el, "can't be blank") unless el.val()


  submitForm: ->
    type = @element.find('input[name=media_type]:checked').val()

    switch type
      when 'image_url'
        attrs = {src: @element.find('#media_image_url').val()}
        attrs['align'] = alignment if alignment = @element.find('#media_image_alignment').val()
        attrs['style'] = '';
        attrs['style'] += 'float: ' + float + '; ' if float = @element.find('#media_image_float').val()
        attrs['style'] += 'width: ' + width + 'px; ' if width = @element.find('#media_image_width').val()
        attrs['style'] += 'height: ' + height + 'px;' if height = @element.find('#media_image_height').val()
        attrs['alt'] = alt if alt = @element.find('#media_image_alt').val()
        Mercury.trigger('action', {action: 'insertImage', value: attrs})

      when 'audio_url'
        url = @element.find('#media_audio_url').val()
        value = '<audio controls=""><source src=' + url + '></audio>';
        Mercury.trigger('action', {action: 'insertHTML', value: value})

      when 'youtube_url'
        url = @element.find('#media_youtube_url').val()
        code = url.replace(/https?:\/\/youtu.be\//, '')
        protocol = 'http'
        protocol = 'https' if /^https:/.test(url)
        value = jQuery('<iframe>', {
          width: parseInt(@element.find('#media_youtube_width').val(), 10) || 560,
          height: parseInt(@element.find('#media_youtube_height').val(), 10) || 349,
          src: "#{protocol}://www.youtube.com/embed/#{code}?wmode=transparent",
          frameborder: 0,
          allowfullscreen: 'true'
        })
        Mercury.trigger('action', {action: 'insertHTML', value: value})

      when 'vimeo_url'
        url = @element.find('#media_vimeo_url').val()
        code = url.replace(/^https?:\/\/vimeo.com\//, '')
        protocol = 'http'
        protocol = 'https' if /^https:/.test(url)
        value = jQuery('<iframe>', {
          width: parseInt(@element.find('#media_vimeo_width').val(), 10) || 400,
          height: parseInt(@element.find('#media_vimeo_height').val(), 10) || 225,
          src: "#{protocol}://player.vimeo.com/video/#{code}?title=1&byline=1&portrait=0&color=ffffff",
          frameborder: 0
        })
        Mercury.trigger('action', {action: 'insertHTML', value: value})

}
