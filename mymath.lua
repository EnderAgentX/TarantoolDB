local mymath =  {}

function mymath.add(a,b)
   print(a+b)
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

function mymath.my_user(user_id)
    return box.space.user.index.primary:get{user_id}
end

return mymath	