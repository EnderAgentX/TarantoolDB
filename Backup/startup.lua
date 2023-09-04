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


-- PATH = ~/ProjectsGO/src/stonefalcon.com/dbservice/db
---------------------------------------------------------------------------------------------------------------------
--             Структура базы данных
---------------------------------------------------------------------------------------------------------------------
--    user_info = {user_id, user_name, last_time}
---------------------------------------------------------------------------------------------------------------------

local idx_user_info_id = 1; local idx_user_info_name = 2; local idx_user_info_last_login_time = 3

---------------------------------------------------------------------------------------------------------------------
--    fb = {user_id, fb_id}
---------------------------------------------------------------------------------------------------------------------
local idx_fb_user_id = 1; local idx_fb_id = 2

---------------------------------------------------------------------------------------------------------------------
--    game center - gc = {gc_id, user_id}
---------------------------------------------------------------------------------------------------------------------
local idx_gc_id = 1; local idx_gc_user_id = 2

---------------------------------------------------------------------------------------------------------------------
--    sessions = {user_id, session_id, last_time}
---------------------------------------------------------------------------------------------------------------------
local idx_sessions_user_id = 1; local idx_sessions_session_id = 2; local idx_sessions_last_time = 3

box.once('schema', function()	
	-- Созаем спейсы и индексы, если их еще нет
	
	-- user_info = [user_id, user_name, last_time]
	local s_user_info = box.schema.space.create( 'user_info' )
	
	s_user_info:create_index('user_id', {unique = true, type = 'HASH', parts = {idx_user_info_id, 'STR'}}) -- Primary index		
	
	-- fb = [fb_id, user_id]
	local s_fb = box.schema.space.create( 'fb' )
	s_fb:create_index('fb_user_id', {unique = true, type = 'HASH', parts = {idx_fb_user_id, 'STR'}}) -- Primary index
	s_fb:create_index('fb_id', {unique = true, type = 'HASH', parts = {idx_fb_id, 'STR'}}) 	
	
	-- gc = [gc_id, user_id]
	local s_gc = box.schema.space.create( 'gc' )
	s_gc:create_index('gc_id', {unique = true, type = 'HASH', parts = {idx_gc_id, 'STR'}}) -- Primary index
	s_gc:create_index('gc_user_id', {unique = true, type = 'HASH', parts = {idx_gc_user_id, 'STR'}})
	
	-- sessions = 
	local s_sessions = box.schema.space.create( 'sessions' )
	
	s_sessions:create_index('user_id', {unique = true, type = 'HASH', parts = {idx_sessions_user_id, 'STR'}}) -- Primary
	s_sessions:create_index('session_id', {unique = true, type = 'HASH', parts = {idx_sessions_session_id, 'STR'}})

---------------------------------------------------------------------------------------------------------------------
--             Создаем пользователей и права доступа
---------------------------------------------------------------------------------------------------------------------
	box.schema.user.create('golang', {password = 'test'})
	box.schema.role.create('dbexec')
	box.schema.func.create('create_anonymous_user', {setuid = true})
	box.schema.role.grant('dbexec','execute', 'function','create_anonymous_user')
--	box.schema.role.grant('dbexec','execute', 'universe')
	box.schema.user.grant('golang','execute','role','dbexec')
	
end ) -- Конец box.once

local s_user_info = box.space.user_info
local s_fb = box.space.fb
local s_gc = box.space.gc
local s_sessions = box.space.sessions

---------------------------------------------------------------------------------------------------------------------
--             Проверка строки на NULL или пустую строку
---------------------------------------------------------------------------------------------------------------------
local function is_str_empty(str)
	return str == nil or str == ''
end


-- Вопрос: как показать, что параметра в таблице нет. Например user_name должно иметь уникальный индекс, при этом как показать, что у пользователя нет user_name

---------------------------------------------------------------------------------------------------------------------
--             Возвращает сессионный ID по User_ID
---------------------------------------------------------------------------------------------------------------------
function get_session_id(user_id)
	local t_session
		
	if not is_str_empty(user_id) then
		local session_id = uuid.bin()
		
		t_session = s_sessions:get{user_id}
				
		if t_session ~= nil then -- сессия для пользователя создана, обновим ее
			t_session = s_sessions:update( user_id, { {'=', idx_sessions_session_id, session_id}, {'=', idx_sessions_last_time, clock.time()} } )
		else
			t_session = s_sessions:insert{ user_id, session_id, clock.time() }
		end
		
		if t_session ~= nil then return t_session[idx_sessions_session_id] end 
	end
	
	return nil
end

---------------------------------------------------------------------------------------------------------------------
--             Возвращает ID пользователя по сессионному ID
---------------------------------------------------------------------------------------------------------------------
function get_user_id(session_id)
	local t_session
	
	if not is_str_empty(session_id) then
		
		t_session = s_sessions.index.session_id:get{session_id}
		
		if t_session ~= nil then			
			if (clock.time() - t_session[idx_sessions_last_time]) < session_life_time then
				
				s_sessions:update(t_session[idx_sessions_user_id],{ {'=', idx_sessions_last_time, clock.time()} }) 				
				return sf_error['ok'], t_session[idx_sessions_user_id]
			
			else return sf_error['user_session_expired'], nil end
		end
	end
	
	return sf_error['not_found'], nil
end

---------------------------------------------------------------------------------------------------------------------
--             Создаем анонимного пользователя
---------------------------------------------------------------------------------------------------------------------
function create_anonymous_user() 	
	local user_id = uuid.bin()
		
	local t_user = s_user_info:insert{user_id, '', clock.time()}
	if t_user ~= nil then return user_id, get_session_id(user_id) end
		
	return nil	
end

---------------------------------------------------------------------------------------------------------------------
--             Определяем, анонимный ли пользователь
---------------------------------------------------------------------------------------------------------------------
function is_anonymous_user( user_id )
	if not is_str_empty(user_id) then -- Смотрим по всем доступным сетям, есть ли связь с этим пользователем
		local t_user = s_fb:get{user_id}
		if t_user == nil then -- связь не найдена, проверим дальше другие сети
			return true -- мы проверили все сети и не нашли ни одной связи - пользователь анонимный
		end
		
		return false -- была найдена связь с соц. сетью, пользователь не анонимный
	end

	return true -- в случае ошибки считаем анонимным
end

---------------------------------------------------------------------------------------------------------------------
--             Присоединить аккаунт фейсбука к текущему пользователю
---------------------------------------------------------------------------------------------------------------------
function link_fb(fb_id, user_id, bl_force_link)
	local t_user
	
	if ( not is_str_empty(fb_id) ) and ( not is_str_empty(user_id) ) then
		local t_fb_user = s_fb.index.fb_id:get{fb_id}
				
		if t_fb_user == nil then -- пользователя с таким fb_id нет
			local t_uid_user = s_fb:get{user_id}
			
			if t_uid_user == nil then -- пользователя с таким user_id нет - можно вставлять связь
				t_user = s_fb:insert{user_id, fb_id}
				
				if t_user ~= nil then return sf_error['ok'], nil end
			else -- найден пользователь с таким user_id, но fb_id у него другой (так как t_fb_user == nil )
				if bl_force_link == true then -- Форсируем линковку нового fb_id, так как пользователь выбрал этот fb_id для себя
					t_user = s_fb:update( user_id, {{'=', idx_fb_id, fb_id}} )
					
					if t_user ~= nil then return sf_error['ok'], nil end
				else
					return sf_error['user_social_overlap'], nil
				end
			end
		elseif t_fb_user[idx_fb_user_id] == user_id then -- найден пользователь с таким fb_id и у него такой же user_id, просто вернем ОК
			return sf_error['ok'], nil
		else -- найден пользователь с таким fb_id, но у него другой user_id - возвращаем ощибку перекрытия профилей, клиент решает что делать
			return sf_error['user_overlap'], t_fb_user[idx_fb_user_id]			
		end
	end
	
	return sf_error['error'], nil	
end

---------------------------------------------------------------------------------------------------------------------
--             Логин анонимного пользователя по UID
---------------------------------------------------------------------------------------------------------------------
function login_anonymous( user_id )	
	
	if not is_str_empty(user_id) then
		if is_anonymous_user( user_id ) then
			local t_user = s_user_info:get{user_id}
			
			if t_user ~= nil then 
				s_user_info:update(user_id,{ {'=', idx_user_info_last_login_time, clock.time()} }) 
				return get_session_id(user_id)
			end
		end		
	end
	
	return nil
end

---------------------------------------------------------------------------------------------------------------------
--             Логин пользователя по FacebookID
---------------------------------------------------------------------------------------------------------------------
function login_fb( fb_id )
	local t_user -- user tuple	
	
	if not is_str_empty(fb_id) then
		t_user = s_fb.index.fb_id:get{fb_id}
		
		if t_user ~= nil then
			local user_id = t_user[idx_fb_user_id]
			if not is_str_empty(user_id) then
				s_user_info:update(user_id,{ {'=', idx_user_info_last_login_time, clock.time()} }) 
				
				return get_session_id(user_id)
			end
		end
	end
	
	return nil
end


---------------------------------------------------------------------------------------------------------------------
--             Для отладки запустим консоль
---------------------------------------------------------------------------------------------------------------------
console.start()