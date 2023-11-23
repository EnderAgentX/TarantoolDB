#!/usr/local/bin tarantool

local uuid = require('uuid')
local console = require('console')
local log = require('log')
local clock = require('clock')

-- Запускаем консоль администратора
console.listen('127.0.0.1:3312')

box.cfg{
	--background          = true,
	listen              = 3301,
	memtx_memory        = 100000000,
	pid_file            = 'tarantool.pid',    
	memtx_dir           = 'snap',
	wal_dir             = 'wal',
	checkpoint_interval = 3600,
	checkpoint_count    = 5,
	log         		= 'tarantool.log'
}

sf_error = {
	ok = 0,
	error = 1,
	not_found = 2,
	update_error = 3,
	
	user_overlap = 100,
	user_social_overlap = 101,
	user_session_expired = 102
}

local session_life_time = 600 -- Время жизни сессии


local function bootstrap()

	local s_user = box.schema.create_space('user')
	s_user:format({
		{name = 'user_id', type = 'string'},
		{name = 'user_name', type = 'string'},
		{name = 'guild_id', type = 'string'}
	})
	s_user:create_index('primary', {
		type = 'tree',
		parts = {'user_id'}
})
	s_user:create_index('name', {
		type = 'tree',
		parts = {'user_name'}
	})

	local s_guild = box.schema.create_space('guild')
	s_guild:format({
		{name = "guild_id", type = 'string'},
		{name = "guild_name", type = 'string'}
	})
	s_guild:create_index('primary', {
			type = 'tree',
			parts = {'guild_id'}
	})
	s_guild:create_index('guild', {
		type = 'tree',
		parts = {'guild_name'}
	})

	local s_msg = box.schema.create_space('msg')
	s_msg:format({
		{name = "msg_id", type = 'string'},
		{name = "message", type = 'string'},
		{name = "guild_id", type = 'string'},
		{name = "user_id", type = 'string'},
		{name = "msg_time", type = 'unsigned'}
	})
	s_msg:create_index('primary', {
		type = 'tree',
		parts = {'msg_id'}
	})
	s_msg:create_index('time', {
		type = 'tree',
		parts = {'msg_time'}

	})
	s_msg:create_index('guild_id', {
		type = 'tree',
		unique = false,
		parts = {'guild_id'}
	})
	
	

	box.schema.user.create('ex', { password = 'secret' })
	box.schema.user.grant('ex','read,write,execute,create,drop','universe')

	box.schema.user.create('repl', { password = 'replication' })
	box.schema.user.grant('repl', 'replication')
end

-- for first run create a space and add set up grants
box.once('replica', bootstrap)

--box.space.guild.index.primary:select()
--box.space.guild:insert{1, 'EscapeWorld'}
--box.space.user:insert{1, 'EnderAgent_X', 1}
--box.space.user.index.primary:select()
--box.space.guild:insert{2, 'Robots'}
--box.space.user:insert{2, 'Bot', 2}

---------------------------------------------------------------------------------------------------------------------
--             Проверка строки на NULL или пустую строку
---------------------------------------------------------------------------------------------------------------------
local function is_str_empty(str)
	return str == nil or str == ''
end


local function get_guild_id(user_id)
	local t_user_id = s_user.index.primary:get{user_id}
	return t_user_id[guild_id]
end



---------------------------------------------------------------------------------------------------------------------
--             Для отладки запустим консоль
---------------------------------------------------------------------------------------------------------------------
mm = require("mymath")

console.start()