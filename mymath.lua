local mymath =  {}

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

return mymath	