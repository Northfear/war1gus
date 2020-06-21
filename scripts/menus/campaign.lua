--      (c) Copyright 2010      by Pali Rohár

function SetupAnimation(filename, w, h, x, y, framecntX, framecntY, backwards, pauseFrameCnt, speedScale, menu)
   local g = CGraphic:New(filename)
   local headW = w / framecntX * (Video.Width / 640)
   local headH = h / framecntY * (Video.Height / 400)
   g:Load()
   g:Resize(headW * framecntX, headH * framecntY)
   local head = ImageWidget(g)
   local headClip = Container()
   headClip:setOpaque(false)
   headClip:setBorderSize(0)
   headClip:setWidth(headW)
   headClip:setHeight(headH)
   headClip:add(head, 0, 0)
   menu:add(headClip, x * Video.Width / 640, y * Video.Height / 400)

   local animTable = {}

   if framecntX > 1 then
      -- animation: frames horizontally
      for i=0,framecntX-1,1 do
         for j=0,speedScale,1 do
            animTable[#animTable + 1] = { -math.ceil(i * headW), 0 }
         end
      end
      if backwards then
         for i=framecntX-1,0,-1 do
            for j=0,speedScale,1 do
               animTable[#animTable + 1] = { -math.ceil(i * headW), 0 }
            end
         end
      end
   else
      -- animation: frames vertically
      for i=0,framecntY-1,1 do
         for j=0,speedScale,1 do
            animTable[#animTable + 1] = { 0, -math.ceil(i * headH) }
         end
      end
      if backwards then
         for i=framecntY-1,0,-1 do
            for j=0,speedScale,1 do
               animTable[#animTable + 1] = { 0, -math.ceil(i * headH) }
            end
         end
      end
   end

   for i=0,pauseFrameCnt,1 do
      animTable[#animTable + 1] = { 0, 0 }
   end

  local frame = 1
  local function animationCb()
     headClip:remove(head)
     headClip:add(head, animTable[frame][1], animTable[frame][2])
     frame = frame + 1
     if frame > #animTable then
        frame = 1
     end
  end

  return animationCb
end

function Briefing(title, objs, bgImg, mapbg, text, voices)
  SetPlayerData(GetThisPlayer(), "RaceName", currentRace)

  local menu = WarMenu()

  local voice = 0
  local channel = -1

  local bg1 = CGraphic:New(bgImg)
  bg1:Load()
  bg1:Resize(Video.Width, Video.Height)
  local bg2 = nil
  if CanAccessFile(mapbg) then
     bg2 = CGraphic:New(mapbg)
     bg2:Load()
     bg2:Resize(Video.Width, Video.Height)
  end

  local bg = ImageButton()
  bg:setNormalImage(bg1)
  menu:add(bg, 0, 0)

  local animations = {}

  if (currentRace == "human") then
    PlayMusic(HumanBriefingMusic)
    LoadUI("human", Video.Width, Video.Height)

    animations[1] = SetupAnimation("graphics/428.png", 240, 48, 166, 74, 5, 1, false, 20, 2, menu)
    animations[2] = SetupAnimation("graphics/429.png", 134, 84 * 21, 414, 59, 1, 21, false, 0, 2, menu)
    animations[3] = SetupAnimation("graphics/430.png", 48, 1008, 42, 36, 1, 21, true, 0, 0, menu)
    animations[4] = SetupAnimation("graphics/431.png", 40, 924, 550, 38, 1, 21, true, 0, 0, menu)

    -- color cycle the shadows
    local coloridx = 1
    local colors = {{48, 56, 56}, {44, 48, 48}, {36, 48, 44}, {52, 64, 64}, {56, 68, 64}, {68, 80, 76}, {72, 84, 80}}
    local function animateFlicker()
       bg1:SetPaletteColor(255, colors[coloridx][1], colors[coloridx][2], colors[coloridx][3])
       coloridx = coloridx + 1
       if coloridx > #colors then
          coloridx = 1
       end
    end
    animations[5] = animateFlicker

  elseif (currentRace == "orc") then
    PlayMusic(OrcBriefingMusic)
    LoadUI("orc", Video.Width, Video.Height)

    animations[1] = SetupAnimation("graphics/426.png", 560, 134, 36, 135, 5, 1, true, 20, 2, menu)
    animations[2] = SetupAnimation("graphics/427.png", 690, 116, 404, 105, 5, 1, true, 0, 2, menu)
    animations[3] = SetupAnimation("graphics/425.png", 100, 2046, 290, 140, 1, 31, false, 0, 0, menu)
  else
    StopMusic()
  end

  local frameTime = 0
  local function animateHeads()
     frameTime = frameTime + 1
     if frameTime % 3 == 0 then
        for i=1,#animations,1 do
           animations[i]()
        end
     end
  end

  listener = LuaActionListener(animateHeads)
  menu:addLogicCallback(listener)

  Objectives = objs

  if (title ~= nil) then
     local headline = title
     if (objs ~= nil) then
        headline = title .. " - " .. objectives[1]
     end
     menu:addLabel(headline, 0.1 * Video.Width, 0.1 * Video.Height, Fonts["large"], false)
  end

  local t = LoadBuffer(text)
  local sw = ScrollingWidget(Video.Width, 0.6 * Video.Height)
  sw:setBackgroundColor(Color(0,0,0,0))
  sw:setSpeed(0.38)

  local l = MultiLineLabel(t)
  l:setForegroundColor(Color(0, 0, 0, 255))
  l:setFont(Fonts["large"])
  l:setAlignment(MultiLineLabel.CENTER)
  l:setVerticalAlignment(MultiLineLabel.BOTTOM)
  l:setLineWidth(0.7 * Video.Width)
  l:adjustSize()
  l:setHeight(0.9 * Video.Height)
  sw:add(l, 0, 0)
  menu:add(sw, 0.15 * Video.Width, 0.2 * Video.Height)

  function PlayNextVoice()
    voice = voice + 1
    if (voice <= table.getn(voices)) then
      channel = PlaySoundFile(voices[voice], PlayNextVoice);
    else
      channel = -1
    end
  end
  PlayNextVoice()

  local speed = GetGameSpeed()
  SetGameSpeed(30)

  local currentAction = nil
  function action2()
     if (channel ~= -1) then
        voice = table.getn(voices)
        StopChannel(channel)
     end
     StopMusic()
     MusicStopped()
     menu:stop()
  end
  function action1()
     if bg2 ~= nil then
        bg:setNormalImage(bg2)
        head1:setVisible(false)
        head2:setVisible(false)
        currentAction = action2
     else
        action2()
     end
  end
  currentAction = action1

  local overall = ImageButton()
  overall:setWidth(Video.Width)
  overall:setHeight(Video.Height)
  overall:setBorderSize(0)
  overall:setBaseColor(Color(0, 0, 0, 0))
  overall:setForegroundColor(Color(0, 0, 0, 0))
  overall:setBackgroundColor(Color(0, 0, 0, 0))
  overall:setActionCallback(function()
        currentAction()
  end)

  l:setActionCallback(action2)
  sw:setActionCallback(action2)

  menu:add(overall, 0, 0)
  menu:run()

  SetGameSpeed(speed)
end

function GetCampaignState(race)
  if (race == "orc") then
    return preferences.CampaignOrc
  elseif (race == "human") then
    return preferences.CampaignHuman
  end
  return 1
end

function IncreaseCampaignState(race, state)
  -- Loaded saved game could have other old state
  -- Make sure that we use saved state from config file
  if (race == "orc") then
    if (state ~= preferences.CampaignOrc) then return end
    preferences.CampaignOrc = preferences.CampaignOrc + 1
  elseif (race == "human") then
    if (state ~= preferences.CampaignHuman) then return end
    preferences.CampaignHuman = preferences.CampaignHuman + 1
  end
  -- Make sure that we immediately save state
  SavePreferences()
end

function CreateEndingStep(bg, text, voice, video)
  return function()
      print ("Ending in " .. bg .. " with " .. text .. " and " .. voice)
	  local menu = WarMenu(nil, bg, true)
	  StopMusic()

          if (video ~= nil) then
             PlayMovie(video)
          end
          
	  local t = LoadBuffer(text)
	  t = "\n\n\n\n\n\n\n\n\n\n" .. t .. "\n\n\n\n\n\n\n\n\n\n\n\n\n"
	  local sw = ScrollingWidget(320, 170 * Video.Height / 480)
	  sw:setBackgroundColor(Color(0,0,0,0))
	  sw:setSpeed(0.28)
	  local l = MultiLineLabel(t)
	  l:setFont(Fonts["large"])
	  l:setAlignment(MultiLineLabel.LEFT)
	  l:setVerticalAlignment(MultiLineLabel.TOP)
	  l:setLineWidth(320)
	  l:adjustSize()
	  sw:add(l, 0, 0)
	  menu:add(sw, 70 * Video.Width / 640, 80 * Video.Height / 480)
	  local channel = -1
	  menu:addHalfButton("~!Continue", "c", 455 * Video.Width / 640, 440 * Video.Height / 480,
		function()
		  if (channel ~= -1) then
			StopChannel(channel)
		  end
		  menu:stop()
		  StopMusic()
		end)
          channel = PlaySoundFile(voice, function() end);
	  menu:run()
	  GameResult = GameVictory
  end
end

function CreatePictureStep(bg, sound, title, text)
  return function()
    SetPlayerData(GetThisPlayer(), "RaceName", currentRace)
    PlayMusic(sound)
    local menu = WarMenu(nil, bg)
    local offx = (Video.Width - 640) / 2
    local offy  = (Video.Height - 480) / 2
    menu:addLabel(title, offx + 320, offy + 240 - 67, Fonts["large-title"], true)
    menu:addLabel(text, offx + 320, offy + 240 - 25, Fonts["small-title"], true)
    menu:addHalfButton("~!Continue", "c", 455 * Video.Width / 640, 440 * Video.Height / 480,
      function() menu:stop() end)
    menu:run()
    GameResult = GameVictory
  end
end

function CreateMapStep(race, map)
  return function()
    -- If there is a pre-setup step, run it, if that fails, don't worry
    local prefix = "campaigns/" .. race .. "/"
    pcall(function () Load(prefix .. map .. "_prerun.lua") end)
    Load(prefix .. map .. "_c2.sms")
    Load(prefix .. "campaign_titles.lua")

    local race_prefix = string.lower(string.sub(race, 1, 1))

    Briefing(
       campaign_titles[tonumber(map)],
       objectives,
       "../graphics/ui/" .. race .. "/briefing.png",
       "../graphics/" .. race_prefix .. "map" .. map .. ".png",
       prefix .. map .. "_intro.txt",
       {prefix .. map .. "_intro.wav"}
    )

    PlayMovie("videos/" .. race_prefix .. "map" .. map .. ".ogv")

    war1gus.InCampaign = true
    Load(prefix .. map .. ".smp")
    RunMap(prefix .. map .. ".smp", preferences.FogOfWar)
    if (GameResult == GameVictory) then
      IncreaseCampaignState(currentRace, currentState)
    end
  end
end

function CreateVictoryStep(bg, text, voices)
  return function()
    Briefing(nil, nil, bg, text, voices)
    GameResult = GameVictory
  end
end

function CampaignButtonTitle(race, i)
  Load("campaigns/" .. race .. "/campaign_titles.lua")
  title = campaign_titles[i] or "xxx"

  if ( string.len(title) > 20 ) then
	  title = string.sub(title, 1, 19) .. "..."
  end

  return title
end

function CampaignButtonFunction(campaign, race, i, menu)
  return function()
    position = campaign.menu[i]
    currentCampaign = campaign
    currentRace = race
    currentState = i
    menu:stop()
    RunCampaign(campaign)
  end
end

function RunCampaignSubmenu(race)
  Load("scripts/campaigns.lua")
  campaign = CreateCampaign(race)

  currentRace = race
  SetPlayerData(GetThisPlayer(), "RaceName", currentRace)

  local menu = WarMenu()
  local offx = (Video.Width - 640) / 2
  local offy = (Video.Height - 480) / 2

  local show_buttons = GetCampaignState(race)
  local half = math.ceil(show_buttons/2)

  for i=1,half do
    menu:addFullButton(CampaignButtonTitle(race, i), ".", offx + 63, offy + 64 + (36 * i), CampaignButtonFunction(campaign, race, i, menu))
  end

  for i=1+half,show_buttons do
    menu:addFullButton(CampaignButtonTitle(race, i), ".", offx + 329, offy + 64 + (36 * (i - half)), CampaignButtonFunction(campaign, race, i, menu))
  end

  menu:addFullButton("~!Previous Menu", "p", offx + 193, offy + 212 + (36 * 5),
    function() menu:stop(); currentCampaign = nil; currentRace = nil; currentState = nil; RunCampaignGameMenu() end)
  menu:run()

end

function RunCampaign(campaign)
  if (campaign ~= currentCampaign or position == nil) then
    position = 1
  end

  currentCampaign = campaign

  while (position <= table.getn(campaign.steps)) do
    campaign.steps[position]()
    if (GameResult == GameVictory) then
      position = position + 1
    elseif (GameResult == GameDefeat) then
    elseif (GameResult == GameDraw) then
    elseif (GameResult == GameNoResult) then
      currentCampaign = nil
      return
    else
      break -- quit to menu
    end
  end

  RunCampaignSubmenu(currentRace)

  currentCampaign = nil
end

function RunCampaignGameMenu()
  local menu = WarMenu()
  local offx = (Video.Width - 640) / 2
  local offy = (Video.Height - 480) / 2

  menu:addFullButton("~!Orc campaign", "o", offx + 193, offy + 212 + (36 * 0),
    function() RunCampaignSubmenu("orc"); menu:stop() end)
  menu:addFullButton("~!Human campaign", "h", offx + 193, offy + 212 + (36 * 1),
    function() RunCampaignSubmenu("human"); menu:stop() end)

  menu:addFullButton("~!Previous Menu", "p", offx + 193, offy + 212 + (36 * 5),
    function() RunSinglePlayerSubMenu(); menu:stop() end)

  menu:run()
end

