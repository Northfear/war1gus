-- Call is as follows: Boxes may have children. When layout is called, boxes
-- have their reserved sizes in x,y,width,height. They can then layout their
-- children as best they can inside those. Elements report their desired sizes
-- via getWidth(), getHeight(). If nothing is desired, nil is returned, if
-- percentage of parent is desired, a percentage string is returned. When
-- layout() returns, it can be added to a guichan container by calling
-- "addWidgetTo(container)"

Load("scripts/lib/classes.lua")

-- dark = Color(38, 38, 78)
-- clear = Color(200, 200, 120)
-- black = Color(0, 0, 0)

Element = class(function(instance)
      instance.parent = nil
      instance.expands = false
      instance.x = nil
      instance.y = nil
      instance.width = nil
      instance.height = nil
end)

function Element:expanding()
   self.expands = true
   return self
end

function Element:getWidth()
   error("Element subclass did not define getWidth")
end

function Element:getHeight()
   error("Element subclass did not define getHeight")
end

function Element:addWidgetTo(container)
   error("Element subclass did not define addWidgetTo")
end

Box = class(Element,
            function(instance, children)
               Element.init(instance)
               instance.padding = 0
               instance.children = children
            end
)

function Box:withPadding(p)
   self.padding = p
   return self
end

function Box:expanding()
   self.expands = true
   return self
end

function Box:getWidth()
   if self.width == nil then
      self:calculateMinExtent()
   end
   return self.width
end

function Box:getHeight()
   if self.height == nil then
      self:calculateMinExtent()
   end
   return self.height
end

Box.DIRECTION_HORIZONTAL = 1
Box.DIRECTION_VERTICAL = 2

function Box:calculateMinExtent()
   local w = 0
   local h = 0
   local horiz = self.direction == Box.DIRECTION_HORIZONTAL
   for i,child in ipairs(self.children) do
      local cw = child:getWidth()
      if type(cw) == "number" then
         if horiz then
            w = w + cw + self.padding
         else
            w = math.max(w, cw)
         end
      end
      local ch = child:getHeight()
      if type(ch) == "number" then
         if horiz then
            h = math.max(h, ch)
         else
            h = h + ch + self.padding
         end
      end
   end
   self.x = 0
   self.y = 0
   self.width = w + (self.padding * 2)
   self.height = h + (self.padding * 2)
   -- print("Min: " .. self.width .. " x " .. self.height)
end

function Box:layout()
   -- print("XY: " .. self.x .. " - " .. self.y)
   local horiz = self.direction == Box.DIRECTION_HORIZONTAL

   local padding = self.padding
   local totalSpace
   if horiz then
      totalSpace = self.width - padding * 2
   else
      totalSpace = self.height - padding * 2
   end

   local availableSpace = totalSpace - (padding * #self.children)
   local expandingChildren = 0

   for i,child in ipairs(self.children) do
      child.parent = self
      local s
      if horiz then
         s = child:getWidth()
      else
         s = child:getHeight()
      end
      if child.expands then
         expandingChildren = expandingChildren + 1
      end
      if type(s) == "string" then
         local pct = string.match(s, "[0-9]+")
         availableSpace = math.max(availableSpace - (totalSpace * (pct / 100)), 0)
      elseif type(s) == "number" then
         availableSpace = math.max(availableSpace - s, 0)
      elseif s == nil then
         -- boxes with no preference expand to fill available space
         if not child.expands then
            child.expands = true
            expandingChildren = expandingChildren + 1
         end
      else
         error("Invalid child extent: need string, number, or nil")
      end
   end

   local childW = self.width - padding * 2
   local childH = self.height - padding * 2
   local expandingChildrenS = 0
   if expandingChildren > 0 then
      expandingChildrenS = availableSpace / expandingChildren
   end
   local xOff = self.x + self.padding
   local yOff = self.y + self.padding

   for i,child in ipairs(self.children) do
      local s
      if horiz then
         s = child:getWidth()
      else
         s = child:getHeight()
      end
      if type(s) == "string" then
         local pct = string.match(w, "[0-9]+")
         local newS = totalSpace * (pct / 100)
         if child.expands then
            newS = newS + expandingChildrenS
         end
         if horiz then
            childW = newS
         else
            childH = newS
         end
      elseif type(s) == "number" then
         if child.expands then
            s = s + expandingChildrenS
         end
         if horiz then
            childW = s
         else
            childH = s
         end
      elseif w == nil then
         if horiz then
            childW = expandingChildrenS
         else
            childH = expandingChildrenS
         end
      end

      -- print(xOff, yOff, childW, childH)
      child.x = xOff
      child.y = yOff
      child.width = childW
      child.height = childH
      if horiz then
         xOff = xOff + childW + padding
      else
         yOff = yOff + childH + padding
      end
   end
   -- print("done")
end

function Box:addWidgetTo(container, sizeFromContainer)
   if sizeFromContainer then
      self.x = 0 -- containers are relative inside
      self.y = 0
      self.width = container:getWidth()
      self.height = container:getHeight()
      -- print("startsize:" .. self.width .. "x" .. self.height .. "+" .. self.x .. "+" .. self.y)
   end
   self:layout()
   for i,child in ipairs(self.children) do
      child:addWidgetTo(container)
   end
end

HBox = class(Box,
             function(instance, fit, padding)
                Box.init(instance, fit, padding)
                instance.direction = Box.DIRECTION_HORIZONTAL
             end
)

VBox = class(Box,
             function(instance, fit, padding)
                Box.init(instance, fit, padding)
                instance.direction = Box.DIRECTION_VERTICAL
             end
)

LLabel = class(Element,
               function(instance, text, font, center, vCenter)
                  Element.init(instance)
                  instance.label = Label(text)
                  instance.label:setFont(font or Fonts["large"])
                  instance.label:adjustSize()
                  instance.center = center
                  instance.vCenter = vCenter
               end
)

function LLabel:getWidth()
   return self.label:getWidth()
end

function LLabel:getHeight()
   return self.label:getHeight()
end

function LLabel:layout()
   if self.center or center == nil then -- center text by default
      self.x = self.x + (self.width - self.label:getWidth()) / 2
   end
   if self.vCenter then
      self.y = self.y + (self.height - self.label:getHeight()) / 2
   end
end

function LLabel:addWidgetTo(container)
   self:layout()
   container:add(self.label, self.x, self.y)
end

LFiller = class(Element)

function LFiller:getWidth()
   return nil
end

function LFiller:getHeight()
   return nil
end

function LFiller:addWidgetTo(container)
   -- nothing
end

LText = class(LLabel,
              function(instance, text)
                 LLabel.init(instance, text, Fonts["game"])
              end
)

LLargeText = class(LLabel)

LButton = class(Element,
                function(instance, caption, hotkey, callback)
                   Element.init(instance)
                   instance.b = ButtonWidget(caption)
                   instance.b:setHotKey(hotkey)
                   if callback then
                      instance.b:setActionCallback(callback)
                   end
                   instance.b:setBackgroundColor(dark)
                   instance.b:setBaseColor(dark)
                end
)

function LButton:getWidth()
   return 127
end

function LButton:getHeight()
   return 14
end

function LButton:addWidgetTo(container)
   self.b:setSize(self.width, self.height)
   container:add(self.b, self.x, self.y)
end

LImageButton = class(Element,
                     function(instance, caption, hotkey, callback)
                        Element.init(instance)
                        instance.b = ImageButton(caption)
                        instance.b:setHotKey(hotkey)
                        if callback then
                           instance.b:setActionCallback(callback)
                        end
                     end
)

function LImageButton:getWidth()
   return self.b:getWidth()
end

function LImageButton:getHeight()
   return self.b:getHeight()
end

function LImageButton:addWidgetTo(container)
   self.b:setSize(self.width, self.height)
   container:add(self.b, self.x, self.y)
end

LHalfButton = class(LButton)

function LHalfButton:getWidth()
   return 60
end

function LHalfButton:getHeight()
   return 14
end

LSlider = class(Element,
                function(instance, min, max, callback)
                   Element.init(instance)
                   instance.s = Slider(min, max)
                   instance.s:setBaseColor(dark)
                   instance.s:setForegroundColor(clear)
                   instance.s:setBackgroundColor(clear)
                   if callback then
                      instance.s:setActionCallback(function(s) callback(instance.s, s) end)
                   end
                end
)

function LSlider:getWidth()
   return nil
end

function LSlider:getHeight()
   return nil
end

function LSlider:addWidgetTo(container)
   self.s:setSize(self.width, self.height)
   container:add(self.s, self.x, self.y)
end

LListBox = class(Element,
                 function(instance, list)
                    Element.init(instance)
                    instance.bq = ListBoxWidget(60, 60)
                    instance.bq:setBaseColor(black)
                    instance.bq:setForegroundColor(clear)
                    instance.bq:setBackgroundColor(dark)
                    instance.bq:setFont(Fonts["game"])
                    instance.bq.itemslist = list
                 end
)

function LListBox:getWidth()
   return nil
end

function LListBox:getHeight()
   return nil
end

function LListBox:addWidgetTo(container)
   self.bq:setSize(self.width, self.height)
   container:add(self.bq, self.x, self.y)
end

LCheckBox = class(Element,
                  function(instance, caption, callback)
                     Element.init(instance)
                     instance.b = CheckBox(caption)
                     instance.b:setForegroundColor(clear)
                     instance.b:setBackgroundColor(dark)
                     if callback then
                        instance.b:setActionCallback(function(s) callback(instance.b, s) end)
                     end
                     instance.b:setFont(Fonts["game"])
                     instance.b:adjustSize()
                  end
)

function LCheckBox:getWidth()
   return self.b:getWidth()
end

function LCheckBox:getHeight()
   return self.b:getHeight()
end

function LCheckBox:addWidgetTo(container)
   self.b:setSize(self.width, self.height)
   container:add(self.b, self.x, self.y)
end

LTextInputField = class(Element,
                        function(instance, text, callback)
                           Element.init(instance)
                           instance.b = TextField(text)
                           if callback then
                              instance.b:setActionCallback(callback)
                           end
                           instance.b:setFont(Fonts["game"])
                           instance.b:setBaseColor(clear)
                           instance.b:setForegroundColor(clear)
                           instance.b:setBackgroundColor(dark)
                        end
)

function LTextInputField:getWidth()
   return nil
end

function LTextInputField:getHeight()
   return nil
end

function LTextInputField:addWidgetTo(container)
   self.b:setSize(self.width, self.height)
   container:add(self.b, self.x, self.y)
end