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

function mymath.new_msg(message, guild_id, user_id)
   local cnt = box.space.msg:count()
   local tt = 1
   if (cnt == 0) then 
      tt = 1
      print("nil")
   else
      tt = box.space.msg.index.time:select({}, {iterator = 'REQ', limit = 1, sort = 'ask'})[1][1] + 1
      print(tt)
      
   end
   local tm = datetime.now()
   if (message ~= "") then
      box.space.msg:insert{tt, message, guild_id, user_id, tm}
   end
   
end

function mymath.login(user_name)
   t_name = box.space.user.index.name:select(user_name)
   t_guild = t_name[1][3]
   return t_name[1][1], t_guild 
end

function mymath.time_test()
   local tm = datetime.now()
   box.space.msg:insert{1, "ab", 1, tm}
   box.space.msg:select()
   print(tm)
end

function mymath.insertAll()
   box.space.guild:insert{1, 'EscapeWorld'}
   box.space.user:insert{1, 'EnderAgent_X', 1}
   box.space.guild:insert{2, 'Robots'}
   box.space.user:insert{2, 'Bot', 2}
end

function mymath.guild_msg(guild_id)
   t_msg = box.space.msg.index.guild_id:select{guild_id}
   local t_msg_arr = {}
   for i = 1, #t_msg do 
      table.insert( t_msg_arr, t_msg[i][2] )
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

return mymath	


--Последний элемент по времени
--box.space.msg.index.time:select({}, {iterator = 'REQ', limit = 1, sort = 'ask'})