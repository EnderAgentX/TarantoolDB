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
   return box.space.group.index.primary:get{t_user.group_id}.group_name
end


function fn.get_name(user_id)
   return box.space.user.index.primary:get{user_id}[2]

end


function fn.new_msg(message, group, user)
   local msg_id = uuid.bin()
   local group_id = box.space.group.index.group:get(group).group_id
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

function fn.time_group_msg(group, datetime) --загружает сообщения больше определенного времени
   group_id = box.space.group.index.group:get(group).group_id
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
      table.insert( t_msg_arr, {combined_result[i][2], combined_result[i][4], combined_result[i][5]} )
      cnt = cnt + 1
   end
   return cnt, t_msg_arr
end

function fn.new_user(name, pass) 
   local user_id = uuid.bin()
   local hashed_password = digest.sha256(pass)
   if box.space.user.index.name:get(name) ~= nil then
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


function fn.new_group(name, group) 
   local group_id = uuid.bin()
   box.space.usergroup:insert{group_id, name, group}
   box.space.group:insert{group_id, group}
end

function fn.hash_password(password)
   local hashed_password = digest.sha256(password)
   return hashed_password
end

function fn.get_user_groups(name)
   local t_user_groups = box.space.usergroup.index.user:select(name)
   local t_user_groups_names = {}
   for i = 1, #t_user_groups do
      table.insert( t_user_groups_names, t_user_groups[i][3] )
   end
   return t_user_groups_names
end

function fn.del_group(user, group)
   local del_id = box.space.usergroup.index.user_group:select({user, group})[1][1]
   box.space.usergroup.index.primary:delete(del_id)
end

function fn.edit_group(user, group, new_group)
   local del_id = box.space.usergroup.index.user_group:select({user, group})[1][1]
   box.space.usergroup.index.primary:update(del_id, {{'=', 3, new_group}})
   box.space.group.index.primary:update(del_id,{{'=', 2, new_group}})
end





return fn	

--lsof -i :3312
--kill 4593
--Последний элемент по времени
--box.space.msg.index.time:select({}, {iterator = 'REQ', limit = 1, sort = 'ask'})

--TODO 
--1) Переделать id на UUID
--2) Не загружает когда нет сообщений в гильдии