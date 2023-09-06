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
   local t_user = box.space.user.index.secondary:get{user_name}
   local t_user_guild =  t_user.guild_id
   return box.space.guild.index.primary:get{t_user.guild_id}.guild_name
end

function mymath.new_msg(message, guild_id)
   local tt = 1
   if (tt == nil or tt == '') then 
      tt = 1
   else
      tt = box.space.msg.index.time:select({}, {iterator = 'REQ', limit = 1, sort = 'ask'})[1][1] + 1
      print(tt)
      
   end
   local tm = datetime.now()
   local tm = datetime.now()
   box.space.msg:insert{tt, message, 1, tm}
   
end

function mymath.time_test()
   local tm = datetime.now()
   box.space.msg:insert{1, "ab", 1, tm}
   box.space.msg:select()
   print(tm)
end

return mymath	


--Последний элемент по времени
--box.space.msg.index.time:select({}, {iterator = 'REQ', limit = 1, sort = 'ask'})