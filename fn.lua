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
function fn.get_guild_id(user_id)
	local t_user_id = s_user.index.primary:get{user_id}
	return t_user_id[guild_id]
end

function fn.user_guild(user_name)
   local t_user =  box.space.user.index.name:get{user_name}
   local t_user_guild =  t_user.guild_id
   return box.space.guild.index.primary:get{t_user.guild_id}.guild_name
end


function fn.get_name(user_id)
   return box.space.user.index.primary:get{user_id}[2]

end


function fn.new_msg(message, guild_id, user_id)
   local msg_id = uuid.bin()
   local tm = os.time()
   if (message ~= "") then
      box.space.msg:insert{msg_id, message, guild_id, user_id, tm}
   end
   
end

-- function fn.login(user_name)
--    t_name = box.space.user.index.name:select(user_name)
--    t_guild = t_name[1][3]
--    return t_name[1][1], t_guild 
-- end



function fn.time_test()
   local tm = os.time()
   box.space.msg:insert{1, "ab", 1, tm}
   box.space.msg:select()
   print(tm)
end

function fn.insertAll()
   mm.new_guild("EscapeWorld")
   mm.new_guild("Robots")
   mm.new_user("EnderAgent_X","EscapeWorld")
   mm.new_user("Bot","Robots")
end

function fn.guild_msg(guild_id)
   t_msg = box.space.msg.index.guild_id:select{guild_id}
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

-- function fn.time_guild_msg(datetime) --загружает сообщения больше определенного времени
--    t_msg = box.space.msg.index.time:select({datetime}, {iterator = 'GT'})
--    local t_msg_arr = {}
--    local cnt = 0
--    for i = 1, #t_msg do 
--       table.insert( t_msg_arr, {t_msg[i][2], t_msg[i][4], t_msg[i][5]} )
--       cnt = cnt + 1
--    end
--    return cnt, t_msg_arr
-- end

function fn.time_guild_msg(guild, datetime) --загружает сообщения больше определенного времени
   t_msg1 = box.space.msg.index.time:select({datetime}, {iterator = 'GT'})
   t_msg2 = box.space.msg.index.guild_id:select{guild}
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
   box.space.user:insert{user_id, name, hashed_password}
end

function fn.login(name, pass)
   local user_password = box.space.user.index.name:get("artem").pass 
   local hashed_password = digest.sha256(pass)
   if user_password == hashed_password then
      return true
   else 
      return false
   end
end

function fn.new_guild(name) 
   local guild_id = uuid.bin()
   box.space.guild:insert{guild_id, name}
end

function fn.hash_password(password)
   local hashed_password = digest.sha256(password)
   return hashed_password
end






return fn	

--lsof -i :3312
--kill 4593
--Последний элемент по времени
--box.space.msg.index.time:select({}, {iterator = 'REQ', limit = 1, sort = 'ask'})

--TODO 
--1) Переделать id на UUID
--2) Не загружает когда нет сообщений в гильдии