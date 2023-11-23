local uuid = require('uuid')

local mymath =  {}
local datetime = require('datetime')

function mymath.add(a,b)
   return (a+b)
end

function mymath.test()
   return "test"
end

function mymath.sub(a,b)
   print(a-b)
end

function mymath.mul(a,b)
   print(a*b)
end

function mymath.div(a,b)
   print(a/b)
end

local s_users = box.space.user
function mymath.get_guild_id(user_id)
	local t_user_id = s_user.index.primary:get{user_id}
	return t_user_id[guild_id]
end

function mymath.user_guild(user_name)
   local t_user =  box.space.user.index.name:get{user_name}
   local t_user_guild =  t_user.guild_id
   return box.space.guild.index.primary:get{t_user.guild_id}.guild_name
end


function mymath.get_name(user_id)
   return box.space.user.index.primary:get{user_id}[2]

end


function mymath.new_msg(message, guild_id, user_id)
   local msg_id = uuid.bin()
   local tm = os.time()
   if (message ~= "") then
      box.space.msg:insert{msg_id, message, guild_id, user_id, tm}
   end
   
end

function mymath.login(user_name)
   t_name = box.space.user.index.name:select(user_name)
   t_guild = t_name[1][3]
   return t_name[1][1], t_guild 
end



function mymath.time_test()
   local tm = os.time()
   box.space.msg:insert{1, "ab", 1, tm}
   box.space.msg:select()
   print(tm)
end

function mymath.insertAll()
   mm.new_guild("EscapeWorld")
   mm.new_guild("Robots")
   mm.new_user("EnderAgent_X","EscapeWorld")
   mm.new_user("Bot","Robots")
end

function mymath.guild_msg(guild_id)
   t_msg = box.space.msg.index.guild_id:select{guild_id}
   local t_msg_arr = {}
   for i = 1, #t_msg do 
      table.insert( t_msg_arr, {t_msg[i][2], t_msg[i][4], t_msg[i][5]} )
   end
   return t_msg_arr
end

function mymath.users()
   t_users = box.space.user:select()
   local t_users_arr = {}
   for i = 1, #t_users do 
      table.insert( t_users_arr, t_users[i][2] )
   end
   return t_users_arr
end

--TODO Поиск всех сообщений из 1 гильдии больше времени последнего сообщения

-- function mymath.time_guild_msg(datetime) --загружает сообщения больше определенного времени
--    t_msg = box.space.msg.index.time:select({datetime}, {iterator = 'GT'})
--    local t_msg_arr = {}
--    local cnt = 0
--    for i = 1, #t_msg do 
--       table.insert( t_msg_arr, {t_msg[i][2], t_msg[i][4], t_msg[i][5]} )
--       cnt = cnt + 1
--    end
--    return cnt, t_msg_arr
-- end

function mymath.time_guild_msg(guild, datetime) --загружает сообщения больше определенного времени
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

function mymath.new_user(name, guild_name) 
   local user_id = uuid.bin()
   local guild_id = box.space.guild.index.guild:get{guild_name}.guild_id
   box.space.user:insert{user_id, name, guild_id}
end

function mymath.new_guild(name) 
   local guild_id = uuid.bin()
   box.space.guild:insert{guild_id, name}
end




return mymath	

--lsof -i :3312
--kill 4593
--Последний элемент по времени
--box.space.msg.index.time:select({}, {iterator = 'REQ', limit = 1, sort = 'ask'})

--TODO 
--1) Переделать id на UUID
--2) Не загружает когда нет сообщений в гильдии