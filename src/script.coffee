google.load("search", "1");
root = exports ? this 
youtube_queries = ["*", "*", "what are *", "about *", "learn about *"]
image_queries = ["*", "* diagram"]
youtube_url = "https://gdata.youtube.com/feeds/api/videos?q=*query*&start-index=1&max-results=*num*&v=2&alt=jsonc&callback=?"
google_img_url = "http://www.google.com/search?safe=off&site=imghp&tbm=isch&q=*query*"
query_text = ""
root.players = Array(10)
imageSearch = undefined

# Prevent the backspace key from navigating back.
$(document).unbind("keydown").bind "keydown", (event) ->
  doPrevent = false
  if event.keyCode is 8 or event.keyCode is 46
    d = event.srcElement or event.target
    if (d.tagName.toUpperCase() is "INPUT" and (d.type.toUpperCase() is "TEXT" or d.type.toUpperCase() is "PASSWORD" or d.type.toUpperCase() is "FILE")) or d.tagName.toUpperCase() is "TEXTAREA"
      doPrevent = d.readOnly or d.disabled
    else
      doPrevent = true
  event.preventDefault() if doPrevent

# YOUTUBE API STUFF
onPlayerReady = (event) ->
  event.target.mute()
  event.target.playVideo()

create_youtube_player = (num, video_id, height, width) ->
  player = new YT.Player("youtube"+num,
    height: height
    width: width
    videoId: video_id
    playerVars: { 'autoplay': 1, 'controls': 0 , 'showinfo': 0},
    events:
      onReady: onPlayerReady
  )
  $(player.a).mouseover ->
    #console.log("unmuting")
    player.unMute()
  $(player.a).mouseout ->
    #console.log("muting")
    player.mute()
  return player

google_image_callback = (num, start_num) ->
  if imageSearch.results and imageSearch.results.length > 0
    results = imageSearch.results
    i = 0
    #console.log("RESULTS:")
    #console.log(results)
    for i in [0...num] by 1
      img_src = results[i].url
      index = i + start_num
      #console.log(img_src)
      $("#image"+index).attr("src", img_src)
      $("#image"+index).attr("height", $("#image"+index).parent().height())
      #$("#image"+index).parent().attr("vertical-align", "center")

pull_google_images = (query, num, start_num) ->
  imageSearch = new google.search.ImageSearch()
  imageSearch.setSearchCompleteCallback this, google_image_callback, [num, start_num]
  imageSearch.execute query
  google.search.Search.getBranding "branding"

pull_youtube = (query, num, start_num) ->
  query = query.replace(/\ /g, "+")
  url = youtube_url.replace(/\*num\*/g, num).replace(/\*query\*/g, query)
  console.log(url)
  $.getJSON url, (data) ->
    for i in [0...num] by 1
      vid_id = data.data.items[i].id
      div_id = "#youtube"+(start_num+i)
      ###
      div = $("<div id=" + div_id + ">")
      container.parent().append(div)
      container.parent().remove('iframe')
      ###
      container = $(div_id)
      player = root.players[i]
      #console.log("player:")
      #console.log(player)
      if (player)
        #console.log("PLAYER EXISTS")
        player.loadVideoById(vid_id)
        ###
        try
          root.player.loadVideoById(vid_id)
        catch
          setTimeout ->
            root.player.loadVideoById(vid_id)
          , 500
        ###
        return
      height = container.height()
      width = container.width()
      #console.log(vid_id + " " + height + " " + width)
      player = create_youtube_player(i, vid_id, height, width)
      container.append(player)
      #console.log("container:")
      #console.log(container)
      root.players[i] = player
    #console.log(root.players)

pull_wiki = (query) ->
  ###
  TODO: 
    "Read More" link
  ###
  $("#wiki").hide()
  query.replace(/\ /g, "_")
  console.log("query: " + query)
  $.getJSON "http://en.wikipedia.org/w/api.php?action=parse&format=json&callback=?&redirects",
    page: query
    prop: "text"
  , (data) ->
    page = $(data.parse.text["*"])
    dis = "This disambiguation page lists articles associated with the same title."
    if (page.text().indexOf(dis) > 0) # recurse on disambiguation
      #console.log("disambiguation")
      redirects = $("li a[href*=wiki]", page)
      if redirects.length == 0 
        return
      link = $(redirects[0]).text()
      pull_wiki(link)
    else
      intro_html = $(page.filter("p")[0]).addClass("wiki").html()
      intro_html2 = $(page.filter("p")[1]).addClass("wiki").html()
      if (intro_html2.length > intro_html.length)
        intro_html = intro_html2
      intro_html = intro_html.replace(/\/wiki\//g, "http://en.wikipedia.org/wiki/")
      $("#wiki").html(intro_html)
      $('.reference').remove()
      $('.Template-Fact').remove()

      # adjust font to fit in div
      while ( $("#wiki").outerHeight() > ($("#wiki").parent().height()) )
        fontsize = parseInt($("#wiki").css("font-size"))
        newfontsize = fontsize - 1
        $("#wiki").css("font-size", newfontsize)
      $("#wiki").show()

setup_textbox = ->
  c = $("#cool-textbox")
  match = $("<span class='match visible'>")
  c.append match
  blinker = $("<div class='blinker'>")
  c.append blinker
  $(document).on "keypress", (e) ->
    #console.log(e.which)
    if e.which is 13
      search(query_text)
      reset()
      return
    # backspace handling
    if (e.which is 8) or (e.which is 46)
      if query_text.length > 0
        query_text = query_text.substring(0, query_text.length-1)
        to_delete = $("#cool-textbox span:nth-last-child(3)")
        to_delete.remove()
    $(".blinker").hide()
    letter = String.fromCharCode(e.which)
    query_text = query_text + letter
    el = $("<span class='letter'>").html(letter)
    starting_left = (Math.random() * 50) - 50
    starting_top = (Math.random() * 50) - 50
    el.css "left", starting_left
    el.css "top", starting_top
    match.before el
    setTimeout (->
      el.css "left", 0
      el.css "top", 0
      el.addClass "visible"
    ), 50

supplement_query = (query, supplements) ->
  index = parseInt((Math.random(supplements.length)))
  new_query = supplements[index].replace(/\*/g, query)
  console.log(new_query)
  return new_query

reset = ->
  $(document).data("initialState").replaceAll("#rects");
  $(".blinker").show()
  $("#cool-textbox").children().not(".match, .blinker").remove()
  $(".match").html ""
  $("#wiki").html ""
  $("#wiki").css("font-size", "25px")
  query_text = ""

YOUTUBES = 3
IMAGES = 3

search = (query) ->
  reset()
  pull_wiki(query)
  for i in [0...YOUTUBES] by 1
    youtube_query = supplement_query(query, youtube_queries)
    pull_youtube(youtube_query, 1, i)
  for i in [0...IMAGES] by 1
    image_query = supplement_query(query, image_queries)
    pull_google_images(image_query, 1, i)

$(document).ready ->
  $(document).data "initialState", $("#rects").clone(true)
  setup_textbox()
  $("#cool-textbox").focus()

