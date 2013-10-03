root = exports ? this
youtube_queries = ["what are ***", "about ***", "learn about ***"]
youtube_url = "https://gdata.youtube.com/feeds/api/videos?q=***query***&start-index=1&max-results=***num***&v=2&alt=jsonc&callback=?"
query_text = ""

# Prevent the backspace key from navigating back.
$(document).unbind("keydown").bind "keydown", (event) ->
  doPrevent = false
  if event.keyCode is 8
    d = event.srcElement or event.target
    if (d.tagName.toUpperCase() is "INPUT" and (d.type.toUpperCase() is "TEXT" or d.type.toUpperCase() is "PASSWORD" or d.type.toUpperCase() is "FILE")) or d.tagName.toUpperCase() is "TEXTAREA"
      doPrevent = d.readOnly or d.disabled
    else
      doPrevent = true
  event.preventDefault() if doPrevent

# YOUTUBE API STUFF
onPlayerReady = (event) ->
  event.target.playVideo()
  event.target.mute()

create_youtube_player = (num, video_id, height, width) ->
  root.player = new YT.Player("youtube"+num,
    height: height
    width: width
    videoId: video_id
    playerVars: { 'autoplay': 1, 'controls': 0 , 'showinfo': 0},
    events:
      onReady: onPlayerReady
  )

pull_youtube = (query, num, start_num) ->
  query = query.replace(/\ /g, "+")
  url = youtube_url.replace(/\*\*\*num\*\*\*/g, num).replace(/\*\*\*query\*\*\*/g, query)
  console.log(url)
  $.getJSON url, (data) ->
    for i in [0...num] by 1
      vid_id = data.data.items[i].id
      container = $("#youtube"+(start_num+i+1))
      console.log("player:")
      console.log(root.player)
      if (root.player?)
        console.log("PLAYER EXISTS")
        root.player.loadVideoById(vid_id)
        return
      height = container.height()
      width = container.width()
      console.log(vid_id + " " + height + " " + width)
      player = create_youtube_player(i+1, vid_id, height, width)
      container.append(player)
      console.log("container:")
      console.log(container)
      $(player.a).parent().mouseover ->
        console.log("unmuting")
        player.unMute()
      $(player.a).parent().mouseout ->
        console.log("muting")
        player.mute()

pull_wiki = (query) ->
  ###
  TODO: 
    trim parens, pronounciation, etc
    make text proportional to size of div
    "Read More" link
  ###
  query.replace(/\ /g, "_")
  console.log("query: " + query)
  $.getJSON "http://en.wikipedia.org/w/api.php?action=parse&format=json&callback=?",
    page: query
    prop: "text"
  , (data) ->
    page = $(data.parse.text["*"])
    intro_html = $(page.filter("p")[0]).addClass("wiki").html()
    intro_html = intro_html.replace(/\/wiki\//g, "http://en.wikipedia.org/wiki/")
    $("#wiki").html(intro_html)

# Set up basic textbox with event listeners.
setup_textbox = ->
  c = $("#cool-textbox")
  match = $("<span class='match visible'>")
  c.append match
  blinker = $("<div class='blinker'>")
  c.append blinker
  c.focus()
  $(document).on "keypress", (e) ->
    if e.which is 13
      console.log("searching: " + query_text)
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

reset = ->
  $(document).data("initialState").replaceAll("#rects");
  $(".blinker").show()
  $("#cool-textbox").children().not(".match, .blinker").remove()
  $(".match").html ""
  $("#wiki").html ""
  query_text = ""

search = (query) ->
  pull_wiki(query)
  pull_youtube(query, 1, 0)
  reset()

$(document).ready ->
  $(document).data "initialState", $("#rects").clone(true)
  setup_textbox()
