local uuid = require('uuid')
local digest = require('digest')
local datetime = require('datetime')

local fn =  {}




function fn.add(a,b)
   return (a+b)
end

function fn.test()
   return "test"
end

function fn.sub(a,b)
   print(a-b)
end

function fn.mul(a,b)
   print(a*b)
end

function fn.div(a,b)
   print(a/b)
end

local s_users = box.space.user
function fn.get_group_id(user_id)
	local t_user_id = s_user.index.primary:get{user_id}
	return t_user_id[group_id]
end

function fn.user_group(user_name)
   local t_user =  box.space.user.index.name:get{user_name}
   local t_user_group =  t_user.group_id
   return box.space.group.index.group_id:get{t_user.group_id}.group_name
end


function fn.get_name(user_id)
   return box.space.user.index.primary:get{user_id}[2]

end

--fn.new_msg("message", "tt", "artem")

function fn.new_msg(message, group_id, user)
   local msg_id = uuid.str()
   local tm = os.time()
   if (message ~= "") then
      box.space.msg:insert{msg_id, message, group_id, user, tm}
   end
end

-- function fn.login(user_name)
--    t_name = box.space.user.index.name:select(user_name)
--    t_group = t_name[1][3]
--    return t_name[1][1], t_group 
-- end



function fn.time_test()
   local tm = os.time()
   box.space.msg:insert{1, "ab", 1, tm}
   box.space.msg:select()
   print(tm)
end

function fn.insertAll()
   mm.new_group("EscapeWorld")
   mm.new_group("Robots")
   mm.new_user("EnderAgent_X","EscapeWorld")
   mm.new_user("Bot","Robots")
end

function fn.group_msg(group_id)
   t_msg = box.space.msg.index.group_id:select{group_id}
   local t_msg_arr = {}
   for i = 1, #t_msg do 
      table.insert( t_msg_arr, {t_msg[i][2], t_msg[i][4], t_msg[i][5]} )
   end
   return t_msg_arr
end

function fn.users()
   t_users = box.space.user:select()
   local t_users_arr = {}
   for i = 1, #t_users do 
      table.insert( t_users_arr, t_users[i][2] )
   end
   return t_users_arr
end

--TODO Поиск всех сообщений из 1 гильдии больше времени последнего сообщения

-- function fn.time_group_msg(datetime) --загружает сообщения больше определенного времени
--    t_msg = box.space.msg.index.time:select({datetime}, {iterator = 'GT'})
--    local t_msg_arr = {}
--    local cnt = 0
--    for i = 1, #t_msg do 
--       table.insert( t_msg_arr, {t_msg[i][2], t_msg[i][4], t_msg[i][5]} )
--       cnt = cnt + 1
--    end
--    return cnt, t_msg_arr
-- end

function fn.time_group_msg(group_id, datetime) --загружает сообщения больше определенного времени
   t_msg1 = box.space.msg.index.time:select({datetime}, {iterator = 'GT'})
   t_msg2 = box.space.msg.index.group_id:select{group_id}
   local combined_result = {}
   for _, v in ipairs(t_msg1) do
      for _, w in ipairs(t_msg2) do
         if v == w then
            table.insert(combined_result, v)
         end
      end
   end 
   local t_msg_arr = {}
   local cnt = 0
   for i = 1, #combined_result do 
      table.insert( t_msg_arr, {combined_result[i][2], combined_result[i][4], combined_result[i][5], combined_result[i][1]} ) --id тоже возвращяем и пихаем в name listbox
      cnt = cnt + 1
   end
   return cnt, t_msg_arr
end

function fn.new_user(name, pass) 
   local user_id = uuid.str()
   local hashed_password = digest.sha256(pass)
   if box.space.user.index.name:get(name) ~= nil then
      return false
   end
   if name == "system" then
      return false
   end
   box.space.user:insert{user_id, name, hashed_password}
   return true
end

function fn.login(name, pass)
   if box.space.user.index.name:get(name) == nil then
      return false
   end
   local user_password = box.space.user.index.name:get(name).pass 
   local hashed_password = digest.sha256(pass)
   if user_password == hashed_password then
      return true
   else 
      return false
   end
end


function fn.new_group(name, group_id, group)
   local usergroup_id = uuid.str() 
   if isStringOnlySpaces(group_id) then
      return "0"
   end
   if box.space.group.index.group_id:get(group_id) == nil then
      --box.space.usergroup.index.user_group:select({"artem", "testID"}) TODO исправить одинаковые группы с именем
      box.space.usergroup:insert{usergroup_id, name, group_id}
      --if box.space.group.index.group:get(group) == nil then
      box.space.group:insert{group_id, group}
      --end
      return "true"
   else
      return "false"
   end
end

function fn.join_group(name, group_id)
   --local group = box.space.group.index.group_id:get("testID").group_name
   local usergroup_id = uuid.str()
   if box.space.group.index.group_id:get(group_id) ~= nil and box.space.usergroup.index.user_group:select({name, group_id})[1] == nil then
      box.space.usergroup:insert{usergroup_id, name, group_id}
      return box.space.group.index.group_id:get(group_id).group_name
   else
      return "false"
   end
end

--function fn.strChange(str)
--   str = str:gsub("^@+", "")
--   return str
--end

function fn.hash_password(password)
   local hashed_password = digest.sha256(password)
   return hashed_password
end

function fn.get_user_groups(name)
   local t_user_groups = box.space.usergroup.index.user:select(name)
   local t_user_groups_names = {}
   for i = 1, #t_user_groups do
      local group_name = box.space.group.index.group_id:get(t_user_groups[i][3]).group_name
      table.insert( t_user_groups_names, {t_user_groups[i][3], group_name} )
   end
   return t_user_groups_names
end

function fn.del_group(user, group_id)
   local del_id = box.space.usergroup.index.user_group:select({user, group_id})[1][1]
   box.space.usergroup.index.primary:delete(del_id)
   if #box.space.usergroup.index.group_id:select(group_id) == 0 then 
      fn.del_group_msg(group_id)
      box.space.group.index.group_id:delete(group_id)
   end
end

function fn.del_group_msg(group_id)
   local messages = box.space.msg.index.group_id:select(group_id)
   for _, msg in pairs(messages) do
      local id = msg[1]
      box.space.msg.index.primary:delete(id)
   end
end

function fn.edit_group(user, group_id, new_group)

   box.space.group.index.group_id:update(group_id,{{'=', 2, new_group}})
end

function fn.edit_msg(msg_id, new_msg)
   box.space.msg.index.primary:update(msg_id,{{'=', 2, new_msg}})
   local msg = box.space.msg.index.primary:get(msg_id).message
   local user = box.space.msg.index.primary:get(msg_id).user
   local group_id = box.space.msg.index.primary:get(msg_id).group_id
   local group_name = box.space.group.index.group_id:get(group_id).group_name
   return user, group_name, msg
end

function fn.get_selected_msg(msg_id)
   local msg = box.space.msg.index.primary:get(msg_id).message
   local user = box.space.msg.index.primary:get(msg_id).user
   local group_id = box.space.msg.index.primary:get(msg_id).group_id
   local group_name = box.space.group.index.group_id:get(group_id).group_name
   return user, group_name, msg
end

function fn.del_msg(msg_id)
   box.space.msg.index.primary:delete(msg_id)
end


function fn.check_group_id(group_id)
   if isStringOnlySpaces(group_id) then
      return "0"
   end
   if box.space.group.index.group_id:get(group_id) == nil then
      return "true"
   else
      return "false"
   end
end

function isStringOnlySpaces(str)
   return str:gsub("%s+", "") == ""
end





return fn	

--lsof -i :3312
--kill 4593
--Последний элемент по времени
--box.space.msg.index.time:select({}, {iterator = 'REQ', limit = 1, sort = 'ask'})

--TODO 
--1) Переделать id на UUID
--2) Не загружает когда нет сообщений в гильдии