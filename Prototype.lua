--===========================================================================--
-- Copyright (c) 2011-2018 WangXH <kurapica125@outlook.com>                  --
--                                                                           --
-- Permission is hereby granted, free of charge, to any person               --
-- obtaining a copy of this software and associated Documentation            --
-- files (the "Software"), to deal in the Software without                   --
-- restriction, including without limitation the rights to use,              --
-- copy, modify, merge, publish, distribute, sublicense, and/or sell         --
-- copies of the Software, and to permit persons to whom the                 --
-- Software is furnished to do so, subject to the following                  --
-- conditions:                                                               --
--                                                                           --
-- The above copyright notice and this permission notice shall be            --
-- included in all copies or substantial portions of the Software.           --
--                                                                           --
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,           --
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES           --
-- OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND                  --
-- NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT               --
-- HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,              --
-- WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING              --
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR             --
-- OTHER DEALINGS IN THE SOFTWARE.                                           --
--===========================================================================--

--===========================================================================--
--                                                                           --
--               Prototype Lua Object-Oriented Program System                --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2017/04/02                                               --
-- Update Date  :   2018/03/12                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

-------------------------------------------------------------------------------
--                                preparation                                --
-------------------------------------------------------------------------------
do
    -----------------------------------------------------------------------
    --                      environment preparation                      --
    -----------------------------------------------------------------------
    local cerror, cformat       = error, string.format
    local _PLoopEnv             = setmetatable(
        {
            _G                  = _G,
            LUA_VERSION         = tonumber(_VERSION and _VERSION:match("[%d%.]+")) or 5.1,

            -- Weak Mode
            WEAK_KEY            = { __mode = "k", __metatable = false },
            WEAK_VALUE          = { __mode = "v", __metatable = false },
            WEAK_ALL            = { __mode = "kv",__metatable = false },

            -- Iterator
            ipairs              = ipairs(_G),
            pairs               = pairs (_G),
            next                = next,
            select              = select,

            -- String
            strlen              = string.len,
            strformat           = string.format,
            strfind             = string.find,
            strsub              = string.sub,
            strbyte             = string.byte,
            strchar             = string.char,
            strrep              = string.rep,
            strgsub             = string.gsub,
            strupper            = string.upper,
            strlower            = string.lower,
            strmatch            = string.match,
            strgmatch           = string.gmatch,

            -- Table
            tblconcat           = table.concat,
            tinsert             = table.insert,
            tremove             = table.remove,
            unpack              = table.unpack or unpack,
            sort                = table.sort,
            setmetatable        = setmetatable,
            getmetatable        = getmetatable,
            rawset              = rawset,
            rawget              = rawget,

            -- Type
            type                = type,
            tonumber            = tonumber,
            tostring            = tostring,

            -- Math
            floor               = math.floor,
            mlog                = math.log,
            mabs                = math.abs,

            -- Coroutine
            create              = coroutine.create,
            resume              = coroutine.resume,
            running             = coroutine.running,
            status              = coroutine.status,
            wrap                = coroutine.wrap,
            yield               = coroutine.yield,

            -- Safe
            pcall               = pcall,
            error               = error,
            print               = print,
            newproxy            = newproxy or false,

            -- In lua 5.2, the loadstring is deprecated
            loadstring          = loadstring or load,
            loadfile            = loadfile,

            -- Debug lib
            debug               = debug or false,
            debuginfo           = debug and debug.getinfo or false,
            getupvalue          = debug and debug.getupvalue or false,
            getlocal            = debug and debug.getlocal or false,
            traceback           = debug and debug.traceback or false,
            setfenv             = setfenv or debug and debug.setfenv or false,
            getfenv             = getfenv or debug and debug.getfenv or false,
            collectgarbage      = collectgarbage,

            -- Share API
            fakefunc            = function() end,
        }, {
            __index             = function(self, k) cerror(cformat("Global variable %q can't be found", k), 2) end,
            __metatable         = true,
        }
    )
    _PLoopEnv._PLoopEnv         = _PLoopEnv
    if setfenv then setfenv(1, _PLoopEnv) else _ENV = _PLoopEnv end

    -----------------------------------------------------------------------
    -- The table contains several settings can be modified based on the
    -- target platform and frameworks. It must be provided before loading
    -- the PLoop, and the table and its fields are all optional.
    --
    -- @table PLOOP_PLATFORM_SETTINGS
    -----------------------------------------------------------------------
    PLOOP_PLATFORM_SETTINGS     = (function(default)
        local settings = _G.PLOOP_PLATFORM_SETTINGS
        if type(settings) == "table" then
            _G.PLOOP_PLATFORM_SETTINGS = nil

            for k, v in pairs, default do
                local r = settings[k]
                if r ~= nil then
                    if type(r) ~= type(v) then
                        Error("The PLOOP_PLATFORM_SETTINGS[%q]'s value must be %s.", k, type(v))
                    else
                        default[k]  = r
                    end
                end
            end
        end
        return default
    end) {
        --- Whether the attribute system use warning instead of error for
        -- invalid attribute target type.
        -- Default false
        -- @owner       PLOOP_PLATFORM_SETTINGS
        ATTR_USE_WARN_INSTEAD_ERROR         = false,

        --- Whether the environmet allow global variable be nil, if false,
        -- things like ture(spell error) could trigger error.
        -- Default true
        -- @owner       PLOOP_PLATFORM_SETTINGS
        ENV_ALLOW_GLOBAL_VAR_BE_NIL         = true,

        --- Whether allow old style of type definitions like :
        --      class "A"
        --          -- xxx
        --      endclass "A"
        --
        -- Default false
        -- @owner       PLOOP_PLATFORM_SETTINGS
        TYPE_DEFINITION_WITH_OLD_STYLE      = false,

        --- Whether the type validation should be disabled. The value should be
        -- false during development, toggling it to true will make the system
        -- ignore the value valiation in several conditions for speed.
        TYPE_VALIDATION_DISABLED            = false,

        --- Whether all old objects keep using new features when their
        -- classes or extend interfaces are re-defined.
        -- Default false
        -- @owner       PLOOP_PLATFORM_SETTINGS
        CLASS_NO_MULTI_VERSION_CLASS        = false,

        --- Whether all interfaces & classes only use the classic format
        -- `Super.Method(obj, ...)` to call super's features, don't use new
        -- style like :
        --      Super[obj].Name = "Ann"
        --      Super[obj].OnNameChanged = Super[obj].OnNameChanged + print
        --      Super[obj]:Greet("King")
        -- Default false
        -- @owner       PLOOP_PLATFORM_SETTINGS
        CLASS_NO_SUPER_OBJECT_STYLE         = false,

        --- Whether all interfaces has anonymous class, so it can be used
        -- to generate object
        -- Default false
        -- @owner       PLOOP_PLATFORM_SETTINGS
        INTERFACE_ALL_ANONYMOUS_CLASS       = false,

        --- Whether all class objects can't save value to fields directly,
        -- So only init fields, properties, events can be set during runtime.
        -- Default false
        -- @owner       PLOOP_PLATFORM_SETTINGS
        OBJECT_NO_RAWSEST                   = false,

        --- Whether all class objects can't fetch nil value from it, combine it
        -- with @OBJ_NO_RAWSEST will force a strict mode for development.
        -- Default false
        -- @owner       PLOOP_PLATFORM_SETTINGS
        OBJECT_NO_NIL_ACCESS                = false,

        --- Whether save the creation places (source and line) for all objects
        -- Default false
        -- @owner       PLOOP_PLATFORM_SETTINGS
        OBJECT_DEBUG_SOURCE                 = false,

        --- The Log level used in the Prototype core part.
        --          1 : Trace
        --          2 : Debug
        --          3 : Info
        --          4 : Warn
        --          5 : Error
        --          6 : Fatal
        -- Default 3(Info)
        -- @owner       PLOOP_PLATFORM_SETTINGS
        CORE_LOG_LEVEL                      = 3,

        --- The core log handler works like :
        --      function CORE_LOG_HANDLER(message, loglevel)
        --          -- message  : the log message
        --          -- loglevel : the log message's level
        --      end
        -- Default print
        -- @owner       PLOOP_PLATFORM_SETTINGS
        CORE_LOG_HANDLER                    = print,

        --- Whether the system is used in a platform where multi os threads
        -- share one lua-state, so the access conflict can't be ignore.
        -- Default false
        -- @owner       PLOOP_PLATFORM_SETTINGS
        MULTI_OS_THREAD                     = false,

        --- Whether the system is used in a platform where multi os threads
        -- share one lua-state, and the lua_lock and lua_unlock apis are
        -- applied, so PLoop don't need to care about the thread conflict.
        -- Default false
        -- @owner       PLOOP_PLATFORM_SETTINGS
        MULTI_OS_THREAD_LUA_LOCK_APPLIED    = false,

        --- Whether the system send warning messages when the system is used
        -- in a platform where multi os threads share one lua-state, and
        -- global variables are saved not to the environment but an inner
        -- cache, it'd solve the thread conflict, but the environment need
        -- fetch them by __index meta-call, so it's better to declare local
        -- variables to hold them for best access speed.
        -- Default true
        -- @owner       PLOOP_PLATFORM_SETTINGS
        MULTI_OS_THREAD_ENV_AUTO_CACHE_WARN = true,

        --- Whether the system use tables for the types of namespace, class and
        -- others, and save the type's meta data in themselves. Normally it's
        -- not recommended.
        --
        -- When the @MULTI_OS_THREAD is true, to avoid the thread conflict, the
        -- system would use a clone-replace mechanism for inner storage, it'd
        -- leave many tables to be collected during the definition time.
        -- Default false
        -- @owner       PLOOP_PLATFORM_SETTINGS
        UNSAFE_MODE                         = false,

        --- Whether try to save the stack data into the exception object, so
        -- we can have more details about the exception.
        -- Default true
        EXCEPTION_SAVE_STACK_DATA           = true,
    }

    -- Special constraint
    if PLOOP_PLATFORM_SETTINGS.MULTI_OS_THREAD then
        PLOOP_PLATFORM_SETTINGS.CLASS_NO_MULTI_VERSION_CLASS = false
    end

    -----------------------------------------------------------------------
    --                               share                               --
    -----------------------------------------------------------------------
    strtrim                     = function (s)    return s and strgsub(s, "^%s*(.-)%s*$", "%1") or "" end
    readOnly                    = function (self) error(strformat("The %s can't be written", tostring(self)), 2) end
    writeOnly                   = function (self) error(strformat("The %s can't be read",    tostring(self)), 2) end
    wipe                        = function (t)    for k in pairs, t do t[k] = nil end return t end
    getfield                    = function (self, key) return self[key] end
    safeget                     = function (self, key) local ok, ret = pcall(getfield, self, key) if ok then return ret end end
    loadInitTable               = function (obj, initTable) for name, value in pairs, initTable do obj[name] = value end end
    getprototypemethod          = function (target, method) local func = safeget(getmetatable(target), method) return type(func) == "function" and func or nil end
    getobjectvalue              = function (target, method, useobjectmethod, ...) local func = useobjectmethod and safeget(target, method) or safeget(getmetatable(target), method) if type(func) == "function" then return func(target, ...) end end
    uinsert                     = function (self, val) for _, v in ipairs, self, 0 do if v == val then return end end tinsert(self, val) end
    diposeObj                   = function (obj) obj:Dispose() end
    newflags                    = (function() local k return function(init) if init then k = type(init) == "number" and init or 1 else k = k * 2 end return k end end)()

    -----------------------------------------------------------------------
    --                              storage                              --
    -----------------------------------------------------------------------
    newStorage                  = PLOOP_PLATFORM_SETTINGS.MULTI_OS_THREAD and function() return {} end or function(weak) return setmetatable({}, weak) end
    saveStorage                 = PLOOP_PLATFORM_SETTINGS.MULTI_OS_THREAD and function(self, key, value)
                                        local new
                                        if value == nil then
                                            if self[key] == nil then return end
                                            new  = {}
                                        else
                                            if self[key] ~= nil then self[key] = value return self end
                                            new  = { [key] = value }
                                        end
                                        for k, v in pairs, self do if k ~= key then new[k] = v end end
                                        return new
                                    end or function(self, key, value) self[key] = value return self end

    -----------------------------------------------------------------------
    --                               debug                               --
    -----------------------------------------------------------------------
    getCallLine                 = not debuginfo and fakefunc or function (stack)
        local info = debuginfo((stack or 2) + 1, "lS")
        if info then
            return "@" .. (info.short_src or "unknown") .. ":" .. (info.currentline or "?")
        end
    end
    parsestack                  = function (stack) return type(stack) == "number" and stack or 1 end

    -----------------------------------------------------------------------
    --                               clone                               --
    -----------------------------------------------------------------------
    deepClone                   = function (src, tar, override, cache)
        if cache then cache[src] = tar end

        for k, v in pairs, src do
            if override or tar[k] == nil then
                if type(v) == "table" and getmetatable(v) == nil then
                    tar[k] = cache and cache[v] or deepClone(v, {}, override, cache)
                else
                    tar[k] = v
                end
            elseif type(v) == "table" and type(tar[k]) == "table" and getmetatable(v) == nil and getmetatable(tar[k]) == nil then
                deepClone(v, tar[k], override, cache)
            end
        end
        return tar
    end

    tblclone                    = function (src, tar, deep, override, safe)
        if src then
            if deep then
                local cache = safe and _Cache()
                deepClone(src, tar, override, cache)   -- no cache for duplicated table
                if safe then _Cache(cache) end
            else
                for k, v in pairs, src do
                    if override or tar[k] == nil then tar[k] = v end
                end
            end
        end
        return tar
    end

    clone                       = function (src, deep, safe)
        if type(src) == "table" and getmetatable(src) == nil then
            return tblclone(src, {}, deep, true, safe)
        else
            return src
        end
    end

    -----------------------------------------------------------------------
    --                          loading snippet                          --
    -----------------------------------------------------------------------
    if LUA_VERSION > 5.1 then
        loadSnippet             = function (chunk, source, env)
            Debug("[core][loadSnippet] ==> %s ....", source or "anonymous")
            Trace(chunk)
            Trace("[core][loadSnippet] <== %s", source or "anonymous")
            return loadstring(chunk, source, nil, env or _PLoopEnv)
        end
    else
        loadSnippet             = function (chunk, source, env)
            Debug("[core][loadSnippet] ==> %s ....", source or "anonymous")
            Trace(chunk)
            Trace("[core][loadSnippet] <== %s", source or "anonymous")
            local v, err = loadstring(chunk, source)
            if v then setfenv(v, env or _PLoopEnv) end
            return v, err
        end
    end

    -----------------------------------------------------------------------
    --                         flags management                          --
    -----------------------------------------------------------------------
    if LUA_VERSION >= 5.3 then
        validateFlags           = loadstring [[
            return function(checkValue, targetValue)
                return (checkValue & (targetValue or 0)) > 0
            end
        ]] ()

        turnOnFlags             = loadstring [[
            return function(checkValue, targetValue)
                return checkValue | (targetValue or 0)
            end
        ]] ()

        turnOffFlags            = loadstring [[
            return function(checkValue, targetValue)
                return (~checkValue) & (targetValue or 0)
            end
        ]] ()
    elseif (LUA_VERSION == 5.2 and type(_G.bit32) == "table") or (LUA_VERSION == 5.1 and type(_G.bit) == "table") then
        local band              = _G.bit32 and _G.bit32.band or _G.bit.band
        local bor               = _G.bit32 and _G.bit32.bor  or _G.bit.bor
        local bnot              = _G.bit32 and _G.bit32.bnot or _G.bit.bnot

        validateFlags           = function (checkValue, targetValue)
            return band(checkValue, targetValue or 0) > 0
        end

        turnOnFlags             = function (checkValue, targetValue)
            return bor(checkValue, targetValue or 0)
        end

        turnOffFlags            = function (checkValue, targetValue)
            return band(bnot(checkValue), targetValue or 0)
        end
    else
        validateFlags           = function (checkValue, targetValue)
            if not targetValue or checkValue > targetValue then return false end
            targetValue = targetValue % (2 * checkValue)
            return (targetValue - targetValue % checkValue) == checkValue
        end

        turnOnFlags             = function (checkValue, targetValue)
            if not validateFlags(checkValue, targetValue) then
                return checkValue + (targetValue or 0)
            end
            return targetValue
        end

        turnOffFlags            = function (checkValue, targetValue)
            if validateFlags(checkValue, targetValue) then
                return targetValue - checkValue
            end
            return targetValue
        end
    end

    -----------------------------------------------------------------------
    --                             newproxy                              --
    -----------------------------------------------------------------------
    newproxy                    = not PLOOP_PLATFORM_SETTINGS.UNSAFE_MODE and newproxy or (function ()
        local falseMeta         = { __metatable = false }
        local proxymap          = newStorage(WEAK_ALL)

        return function (prototype)
            if prototype == true then
                local meta  = {}
                prototype   = setmetatable({}, meta)
                proxymap[prototype] = meta
                return prototype
            elseif proxymap[prototype] then
                return setmetatable({}, proxymap[prototype])
            else
                return setmetatable({}, falseMeta)
            end
        end
    end)()

    -----------------------------------------------------------------------
    --                        environment control                        --
    -----------------------------------------------------------------------
    if not setfenv then
        if debug and debug.getinfo and debug.getupvalue and debug.upvaluejoin and debug.getlocal then
            local getinfo       = debug.getinfo
            local getupvalue    = debug.getupvalue
            local upvaluejoin   = debug.upvaluejoin
            local getlocal      = debug.getlocal

            setfenv             = function (f, t)
                f = type(f) == 'function' and f or getinfo(f + 1, 'f').func
                local up, name = 0
                repeat
                    up = up + 1
                    name = getupvalue(f, up)
                until name == '_ENV' or name == nil
                if name then upvaluejoin(f, up, function() return t end, 1) end
            end

            getfenv             = function (f)
                local cf, up, name, val = type(f) == 'function' and f or getinfo(f + 1, 'f').func, 0
                repeat
                    up = up + 1
                    name, val = getupvalue(cf, up)
                until name == '_ENV' or name == nil
                if val then return val end

                if type(f) == "number" then
                    f, up = f + 1, 0
                    repeat
                        up = up + 1
                        name, val = getlocal(f, up)
                    until name == '_ENV' or name == nil
                    if val then return val end
                end
            end
        else
            getfenv             = fakefunc
            setfenv             = fakefunc
        end
    end
    safesetfenv                 = PLOOP_PLATFORM_SETTINGS.TYPE_DEFINITION_WITH_OLD_STYLE and setfenv or fakefunc

    -----------------------------------------------------------------------
    --                            main cache                             --
    -----------------------------------------------------------------------
    _Cache                      = setmetatable({}, {
        __call                  = PLOOP_PLATFORM_SETTINGS.MULTI_OS_THREAD and
            function(self, tbl) return tbl and wipe(tbl) or {} end
            or
            function(self, tbl) if tbl then return tinsert(self, wipe(tbl)) else return tremove(self) or {} end end,
        }
    )

    -----------------------------------------------------------------------
    --                                log                                --
    -----------------------------------------------------------------------
    local generateLogger        = function (prefix, loglvl)
        local handler = PLOOP_PLATFORM_SETTINGS.CORE_LOG_HANDLER
        return PLOOP_PLATFORM_SETTINGS.CORE_LOG_LEVEL > loglvl and fakefunc or
            function(msg, stack, ...)
                if type(stack) == "number" then
                    msg = prefix .. strformat(msg, ...) .. (getCallLine(stack + 1) or "")
                elseif stack then
                    msg = prefix .. strformat(msg, stack, ...)
                else
                    msg = prefix .. msg
                end
                return handler(msg, loglvl)
            end
    end

    Trace                       = generateLogger("[PLoop:Trace]", 1)
    Debug                       = generateLogger("[PLoop:Debug]", 2)
    Info                        = generateLogger("[PLoop: Info]", 3)
    Warn                        = generateLogger("[PLoop: Warn]", 4)
    Error                       = generateLogger("[PLoop:Error]", 5)
    Fatal                       = generateLogger("[PLoop:Fatal]", 6)

    -----------------------------------------------------------------------
    --                          keyword helper                           --
    -----------------------------------------------------------------------
    local parseParams           = function (keyword, ptype, ...)
        local visitor           = keyword and environment.GetKeywordVisitor(keyword)
        local env, target, definition, flag, stack

        for i = 1, select('#', ...) do
            local v = select(i, ...)
            local t = type(v)

            if t == "boolean" then
                if flag == nil then flag = v end
            elseif t == "number" then
                stack = stack or v
            elseif t == "function" then
                definition = definition or v
            elseif t == "string" then
                v       = strtrim(v)
                if strfind(v, "^%S+$") then
                    target      = target or v
                else
                    definition  = definition or v
                end
            elseif t == "userdata" then
                if ptype and ptype.Validate(v) then
                    target      = target or v
                end
            elseif t == "table" then
                if getmetatable(v) ~= nil then
                    if ptype and ptype.Validate(v) then
                        target  = target or v
                    else
                        env     = env or v
                    end
                elseif v == _G then
                    env         = env or v
                else
                    definition  = definition or v
                end
            end
        end

        -- Default
        stack = stack or 1
        env = env or visitor or getfenv(stack + 3) or _G

        return visitor, env, target, definition, flag, stack
    end

    -- Used for features like property, event, member and namespace
    getFeatureParams            = function (keyword, ftype, ...)
        local  visitor, env, target, definition, flag, stack = parseParams(keyword, ftype, ...)
        return visitor, env, target, definition, flag, stack
    end

    -- Used for types like enum, struct, class and interface : class([env,][name,][definition,][keepenv,][stack])
    getTypeParams               = function (nType, ptype, ...)
        local  visitor, env, target, definition, flag, stack = parseParams(nType, nType, ...)

        if target then
            if type(target) == "string" then
                local path  = target
                local full  = path:find("%p+")
                target      = namespace.GetNamespace(full and ROOT_NAMESPACE or environment.GetNamespace(visitor or env), path)
                if not target then
                    target  = prototype.NewProxy(ptype)
                    namespace.SaveNamespace(full and ROOT_NAMESPACE or environment.GetNamespace(visitor or env), path, target, stack + 2)
                end

                if not nType.Validate(target) then
                    target  = nil
                else
                    if visitor then rawset(visitor, namespace.GetNamespaceName(target, true), target) end
                    if env and env ~= visitor then rawset(env, namespace.GetNamespaceName(target, true), target) end
                end
            end
        else
            -- Anonymous
            target = prototype.NewProxy(ptype)
            namespace.SaveAnonymousNamespace(target)
        end

        return visitor, env, target, definition, flag, stack
    end

    parseDefinition             = function(definition, env, stack)
        if type(definition) == "string" then
            local def, msg  = loadSnippet("return function(_ENV)\n" .. definition .. "\nend", nil, env)
            if def then
                def, msg    = pcall(def)
                if def then
                    definition = msg
                else
                    error(msg, (stack or 1) + 1)
                end
            else
                error(msg, (stack or 1) + 1)
            end
        end
        return definition
    end

    parseNamespace              = function(name, visitor, env)
        if type(name) == "string" and not strfind(name, "%p+") then
            name    = strtrim(name)
            name    = visitor and visitor[name] or env and env[name]
        end
        return name and namespace.Validate(name)
    end
end

-------------------------------------------------------------------------------
-- The prototypes are types of other types(like classes), for a class "A",
-- A is its object's type and the class is A's prototype.
--
-- The prototypes are simple userdata generated like:
--
--      proxy = prototype {
--          __index = function(self, key) return rawget(self, "__" .. key) end,
--          __newindex = function(self, key, value)
--              rawset(self, "__" .. key, value)
--          end,
--      }
--
--      obj = prototype.NewObject(proxy)
--      obj.Name = "Test"
--      print(obj.Name, obj.__Name)
--
-- The prototypes are normally userdata created by newproxy if the newproxy API
-- existed, otherwise a fake newproxy will be used and they will be tables.
--
-- All meta-table settings will be copied to the result's meta-table, and there
-- are two fields whose default value is provided by the prototype system :
--      * __metatable : if nil, the prototype itself would be used.
--      * __tostring  : if its value is string, it'll be converted to a function
--              that return the value, if the prototype name is provided and the
--              __tostring is nil, the name would be used.
--
-- The prototype system also support a simple inheritance system like :
--
--      cproxy = prototype (proxy, {
--          __call = function(self, ...) end,
--      })
--
-- The new prototype's meta-table will copy meta-settings from its super except
-- the __metatable.
--
-- The complete definition syntaxes are
--
--      val = prototype ([name][super,]definiton[,nodeepclone][,stack])
--
-- The params :
--      * name          : string, the prototype's name, it'd be used in the
--              __tostring, if it's not provided.
--
--      * super         : prototype, the super prototype whose meta-settings
--              would be copied to the new one.
--
--      * definition    : table, the prototype's meta-settings.
--
--      * nodeepclone   : boolean, the __index maybe a table, normally, it's
--              content would be deep cloned to the prototype's meta-settings,
--              if true, the __index table will be used directly, so you may
--              modify it after the prototype's definition.
--
--      * stack         : number, the stack level used to raise errors.
--
-- @prototype   prototype
-------------------------------------------------------------------------------
do
    -----------------------------------------------------------------------
    --                         private constants                         --
    -----------------------------------------------------------------------
    local FLD_PROTOTYPE_META    = "__PLOOP_PROTOTYPE_META"

    -----------------------------------------------------------------------
    --                          private storage                          --
    -----------------------------------------------------------------------
    local _Prototype            = PLOOP_PLATFORM_SETTINGS.UNSAFE_MODE
                                    and setmetatable({}, { __index = function(_, p) return type(p) == "table" and rawget(p, FLD_PROTOTYPE_META) or nil end })
                                    or  newStorage(WEAK_ALL)

    -----------------------------------------------------------------------
    --                          private helpers                          --
    -----------------------------------------------------------------------
    local savePrototype         = PLOOP_PLATFORM_SETTINGS.UNSAFE_MODE
                                    and function(p, meta) rawset(p, FLD_PROTOTYPE_META, meta) end
                                    or  function(p, meta) _Prototype = saveStorage(_Prototype, p, meta) end

    local newPrototype          = function (meta, super, nodeepclone, stack)
        local name
        local prototype         = newproxy(true)
        local pmeta             = getmetatable(prototype)

        savePrototype(prototype, pmeta)

        -- Default
        if meta                                 then tblclone(meta, pmeta,  not nodeepclone, true) end
        if pmeta.__metatable        == nil      then pmeta.__metatable      = prototype end
        if type(pmeta.__tostring)   == "string" then name, pmeta.__tostring = pmeta.__tostring, nil end
        if pmeta.__tostring         == nil      then pmeta.__tostring       = name and function() return name end end

        -- Inherit
        if super                                then tblclone(_Prototype[super], pmeta, true, false) end

        Debug("[prototype] %s created", (stack or 1) + 1, name or "anonymous")

        return prototype
    end

    -----------------------------------------------------------------------
    --                             prototype                             --
    -----------------------------------------------------------------------
    prototype                   = newPrototype {
        __tostring              = "prototype",
        __index                 = {
            --- Get the methods of the prototype
            -- @static
            -- @method  GetMethods
            -- @owner   prototype
            -- @format  (prototype[, cache])
            -- @param   prototype                   the target prototype
            -- @param   cache:(table|boolean)       whether save the result in the cache if it's a table or return a cache table if it's true
            -- @rformat (iter, prototype)           without the cache parameter, used in generic for
            -- @return  iter:function               the iterator
            -- @return  prototype                   the prototype itself
            -- @rformat (cache)                     with the cache parameter, return the cache of the methods.
            -- @return  cache
            -- @usage   for name, func in prototype.GetMethods(class) do print(name) end
            -- @usage   for name, func in pairs(prototype.GetMethods(class, true)) do print(name) end
            ["GetMethods"]      = function(self, cache)
                local meta      = _Prototype[self]
                if meta and type(meta.__index) == "table" then
                    local methods = meta.__index
                    if cache then
                        cache   = type(cache) == "table" and wipe(cache) or {}
                        for k, v in pairs, methods do if type(v) == "function" then cache[k] = v end end
                        return cache
                    else
                        return function(self, n)
                            local k, v = next(methods, n)
                            while k and type(v) ~= "function" do k, v = next(methods, k) end
                            return k, v
                        end, self
                    end
                elseif cache then
                    return type(cache) == "table" and cache or nil
                else
                    return fakefunc, self
                end
            end;

            --- Create a proxy with the prototype's meta-table
            -- @static
            -- @method  NewProxy
            -- @owner   prototype
            -- @param   prototype                   the target prototype
            -- @return  proxy:userdata              the proxy of the same meta-table
            -- @usage   clsA = prototype.NewProxy(class)
            ["NewProxy"]        = newproxy;

            --- Create a table(object) with the prototype's meta-table
            -- @static
            -- @method  NewObject
            -- @owner   prototype
            -- @format  (prototype, [object])
            -- @param   prototype                   the target prototype
            -- @param   object:table                the raw-table used to be set the prototype's metatable
            -- @return  object:table                the table with the prototype's meta-table
            ["NewObject"]       = function(self, tbl) return setmetatable(type(tbl) == "table" and tbl or {}, _Prototype[self]) end;

            --- Whether the value is an object(proxy) of the prototype(has the same meta-table),
            -- only works for the prototype that use itself as the __metatable.
            -- @static
            -- @method  ValidateValue
            -- @owner   prototype
            -- @format  (prototype, value[, onlyvalid])
            -- @param   prototype                   the target prototype
            -- @param   value:(table|userdata)      the value to be validated
            -- @param   onlyvalid:boolean           if true use true instead of the error message
            -- @return  value                       the value if it's a value of the prototype, otherwise nil
            -- @return  error                       the error message if the value is not valid
            ["ValidateValue"]   = function(self, val, onlyvalid)
                if getmetatable(val) == self then return val end
                return nil, onlyvalid or ("the %s is not a valid value of [prototype]" .. tostring(self))
            end;

            --- Whether the value is a prototype
            -- @static
            -- @method  Validate
            -- @owner   prototype
            -- @param   prototype                   the prototype to be validated
            -- @return  result:boolean              true if the prototype is valid
            ["Validate"]        = function(self) return _Prototype[self] and self or nil end;
        },
        __newindex              = readOnly,
        __call                  = function (self, ...)
            local meta, super, nodeepclone, stack

            for i = 1, select("#", ...) do
                local value         = select(i, ...)
                local vtype         = type(value)

                if vtype == "boolean" then
                    nodeepclone     = value
                elseif vtype == "number" then
                    stack           = value
                elseif vtype == "table" then
                    if getmetatable(value) == nil then
                        meta        = value
                    elseif _Prototype[value] then
                        super       = value
                    end
                elseif vtype == "userdata" and _Prototype[value] then
                    super           = value
                end
            end

            local prototype         = newPrototype(meta, super, nodeepclone, (stack or 1) + 1)
            return prototype
        end,
    }
end

-------------------------------------------------------------------------------
-- The attributes are used to bind informations to features, or used to modify
-- those features directly.
--
-- The attributes should provide attribute usages.
--
-- The attribute usages are fixed name fields, methods or properties of the
-- attribute:
--
--      * InitDefinition    A method used to modify the target's definition or
--                      init the target before it load its definition, and its
--                      return value will be used as the new definition for the
--                      target if existed.
--          * Parameters :
--              * attribute     the attribute
--              * target        the target like class, method and etc
--              * targettype    the target type, that's a flag value registered
--                      by types. @see attribute.RegisterTargetType
--              * definition    the definition of the target.
--              * owner         the target's owner, it the target is a method,
--                      the owner may be a class or interface that contains it.
--              * name          the target's name, like method name.
--          * Returns :
--              * (definiton)   the return value will be used as the target's
--                      new definition.
--
--      * ApplyAttribute    A method used to apply the attribute to the target.
--                      the method would be called after the definition of the
--                      target. The target still can be modified.
--          * Parameters :
--              * attribute     the attribute
--              * target        the target like class, method and etc
--              * targettype    the target type, that's a flag value registered
--                      by the target type. @see attribute.RegisterTargetType
--              * owner         the target's owner, it the target is a method,
--                      the owner may be a class or interface that contains it.
--              * name          the target's name, like method name.
--
--      * AttachAttribute   A method used to generate attachment to the target
--                      such as runtime document, map to database's tables and
--                      etc. The method would be called after the definition of
--                      the target. The target can't be modified.
--          * Parameters :
--              * attribute     the attribute
--              * target        the target like class, method and etc
--              * targettype    the target type, that's a flag value registered
--                      by the target type. @see attribute.RegisterTargetType
--              * owner         the target's owner, it the target is a method,
--                      the owner may be a class or interface that contains it.
--              * name          the target's name, like method name.
--          * Returns :
--              * (attach)      the return value will be used as attachment of
--                      the attribute's type for the target.
--
--      * AttributeTarget   Default 0 (all types). The flags that represents
--              the type of the target like class, method and other features.
--
--      * Inheritable       Default false. Whether the attribute is inheritable
--              , @see attribute.ApplyAttributes
--
--      * Overridable       Default true. Whether the attribute's saved data is
--              overridable.
--
--      * Priority          Default 0. The attribute's priority, the bigger the
--              first to be applied.
--
--      * SubLevel          Default 0. The priority's sublevel, for attributes
--              with same priority, the bigger sublevel the first be applied.
--
--
-- To fetch the attribute usages from an attribute, take the *ApplyAttribute*
-- as an example, the system will first use `attr["ApplyAttribute"]` to fetch
-- the value, since the system don't care how it's provided, field, property,
-- __index all works.
--
-- If the attribute don't provide attribute usage, the default value will be
-- used.
--
-- Although the attribute system is designed without the type requirement, it's
-- better to define them by creating classes extend @see System.IAttribute
--
-- To use the attribute system on a target within its definition, here is list
-- of actions:
--
--   1. Save attributes to the target.         @see attribute.SaveAttributes
--   2. Inherit super attributes to the target.@see attribute.InheritAttributes
--   3. Modify the definition of the target.   @see attribute.InitDefinition
--   4. Change the target if needed.           @see attribute.ToggleTarget
--   5. Apply the definition on the target.
--   6. Apply the attributes on the target.    @see attribute.ApplyAttributes
--   7. Finish the definition of the target.
--   8. Attach attributes datas to the target. @see attribute.AttachAttributes
--
-- The step 2 can be processed after step 3 since we can't know the target's
-- super before it's definition, but in that case, the inherited attributes
-- can't modify the target's definition.
--
-- The step 2, 3, 4, 6 are all optional.
--
-- @prototype   attribute
-------------------------------------------------------------------------------
do
    -----------------------------------------------------------------------
    --                          public constants                         --
    -----------------------------------------------------------------------
    -- ATTRIBUTE TARGETS
    ATTRTAR_ALL                 = 0

    -----------------------------------------------------------------------
    --                          private storage                          --
    -----------------------------------------------------------------------
    -- Attribute Data
    local _AttrTargetTypes      = { [ATTRTAR_ALL] = "All" }

    -- Attribute Target Data
    local _AttrTargetData       = newStorage(WEAK_KEY)
    local _AttrOwnerSubData     = newStorage(WEAK_KEY)
    local _AttrTargetInrt       = newStorage(WEAK_KEY)

    -- Temporary Cache
    local _RegisteredAttrs      = {}
    local _RegisteredAttrsStack = {}
    local _TargetAttrs          = newStorage(WEAK_KEY)

    -----------------------------------------------------------------------
    --                          private helpers                          --
    -----------------------------------------------------------------------
    local _UseWarnInstreadErr   = PLOOP_PLATFORM_SETTINGS.ATTR_USE_WARN_INSTEAD_ERROR

    local getAttributeData      = function (attrType, target, owner)
        local adata
        if owner then
            adata               = _AttrOwnerSubData[attrType]
            adata               = adata and adata[owner]
        else
            adata               = _AttrTargetData[attrType]
        end
        if adata then return adata[target] end
    end

    local getAttributeUsage     = function (attr)
        local attrData          = _AttrTargetData[attribute]
        return attrData and attrData[getmetatable(attr)]
    end

    local getAttrUsageField     = function (obj, field, default, chkType)
        local val   = obj and safeget(obj, field)
        if val ~= nil and (not chkType or type(val) == chkType) then return val end
        return default
    end

    local getAttributeInfo      = function (attr, field, default, chkType, attrusage)
        local val   = getAttrUsageField(attr, field, nil, chkType)
        if val == nil then val  = getAttrUsageField(attrusage or getAttributeUsage(attr), field, nil, chkType) end
        if val ~= nil then return val end
        return default
    end

    local addAttribute          = function (list, attr, noSameType)
        for _, v in ipairs, list, 0 do
            if v == attr then return end
            if noSameType and getmetatable(v) == getmetatable(attr) then return end
        end

        local idx       = 1
        local priority  = getAttributeInfo(attr, "Priority", 0, "number")
        local sublevel  = getAttributeInfo(attr, "SubLevel", 0, "number")

        while list[idx] do
            local patr  = list[idx]
            local pprty = getAttributeInfo(patr, "Priority", 0, "number")
            local psubl = getAttributeInfo(patr, "SubLevel", 0, "number")

            if priority > pprty or (priority == pprty and sublevel > psubl) then break end
            idx = idx + 1
        end

        tinsert(list, idx, attr)
    end

    local saveAttributeData     = function (attrType, target, data, owner)
        if owner then
            _AttrOwnerSubData   = saveStorage(_AttrOwnerSubData, attrType, saveStorage(_AttrOwnerSubData[attrType] or newStorage(WEAK_KEY), owner, saveStorage(_AttrOwnerSubData[attrType] and _AttrOwnerSubData[attrType][owner] or newStorage(WEAK_KEY), target, data)))
        else
            _AttrTargetData     = saveStorage(_AttrTargetData, attrType, saveStorage(_AttrTargetData[attrType] or newStorage(WEAK_KEY), target, data))
        end
    end

    -----------------------------------------------------------------------
    --                             prototype                             --
    -----------------------------------------------------------------------
    attribute                   = prototype {
        __tostring              = "attribute",
        __index                 = {
            --- Apply the registered attributes to the target before the definition
            -- @static
            -- @method  ApplyAttributes
            -- @owner   attribute
            -- @format  (target, targettype, definition, [owner], [name][, stack])
            -- @param   target                      the target, maybe class, method, object and etc
            -- @param   targettype                  the flag value of the target's type
            -- @param   owner                       the target's owner, like the class for a method
            -- @param   name                        the target's name if it has owner
            -- @param   stack                       the stack level
            ["ApplyAttributes"] = function(target, targettype, owner, name, stack)
                local tarAttrs  = _TargetAttrs[target]
                if not tarAttrs then return end

                stack           = parsestack(stack) + 1

                -- Apply the attribute to the target
                Debug("[attribute][ApplyAttributes] ==> [%s]%s", _AttrTargetTypes[targettype] or "Unknown", owner and ("[" .. tostring(owner) .. "]" .. name) or tostring(target))

                for i, attr in ipairs, tarAttrs, 0 do
                    local ausage= getAttributeUsage(attr)
                    local apply = getAttributeInfo (attr, "ApplyAttribute", nil, "function", ausage)

                    -- Apply attribute before the definition
                    if apply then
                        Trace("Call %s.ApplyAttribute", tostring(attr))
                        apply(attr, target, targettype, owner, name, stack)
                    end
                end

                Trace("[attribute][ApplyAttributes] <== [%s]%s", _AttrTargetTypes[targettype] or "Unknown", owner and ("[" .. tostring(owner) .. "]" .. name) or tostring(target))
            end;

            --- Attach the registered attributes data to the target after the definition
            -- @static
            -- @method  AttachAttributes
            -- @owner   attribute
            -- @format  (target, targettype, [owner], [name][, stack])
            -- @param   target                      the target, maybe class, method, object and etc
            -- @param   targettype                  the flag value of the target's type
            -- @param   owner                       the target's owner, like the class for a method
            -- @param   name                        the target's name if it has owner
            -- @param   stack                       the stack level
            ["AttachAttributes"]= function(target, targettype, owner, name, stack)
                local tarAttrs  = _TargetAttrs[target]
                if not tarAttrs then return else _TargetAttrs[target] = nil end

                local extInhrt  = _AttrTargetInrt[target] and tblclone(_AttrTargetInrt[target], _Cache())
                local newInhrt  = false
                stack           = parsestack(stack) + 1

                -- Apply the attribute to the target
                Debug("[attribute][AttachAttributes] ==> [%s]%s", _AttrTargetTypes[targettype] or "Unknown", owner and ("[" .. tostring(owner) .. "]" .. name) or tostring(target))

                for i, attr in ipairs, tarAttrs, 0 do
                    local aType = getmetatable(attr)
                    local ausage= getAttributeUsage(attr)
                    local attach= getAttributeInfo (attr, "AttachAttribute",nil,    "function", ausage)
                    local ovrd  = getAttributeInfo (attr, "Overridable",    true,   nil,        ausage)
                    local inhr  = getAttributeInfo (attr, "Inheritable",    false,  nil,        ausage)

                    -- Try attach the attribute
                    if attach and (ovrd or getAttributeData(aType, target, owner) == nil) then
                        Trace("Call %s.AttachAttribute", tostring(attr))

                        local ret = attach(attr, target, targettype, owner, name, stack)

                        if ret ~= nil then
                            saveAttributeData(aType, target, ret, owner)
                        end
                    end

                    if inhr then
                        Trace("Save inheritable attribute %s", tostring(attr))

                        extInhrt        = extInhrt or _Cache()
                        extInhrt[aType] = attr
                        newInhrt        = true
                    end
                end

                Trace("[attribute][AttachAttributes] <== [%s]%s", _AttrTargetTypes[targettype] or "Unknown", owner and ("[" .. tostring(owner) .. "]" .. name) or tostring(target))

                _Cache(tarAttrs)

                -- Save
                if newInhrt then
                    _AttrTargetInrt = saveStorage(_AttrTargetInrt, target, extInhrt)
                elseif extInhrt then
                    _Cache(extInhrt)
                end
            end;

            --- Get the attached attribute data of the target
            -- @static
            -- @method  GetAttachedData
            -- @owner   attribute
            -- @format  attributeType, target[, owner]
            -- @param   attributeType               the attribute type
            -- @param   target                      the target
            -- @param   owner                       the target's owner
            -- @return  any                         the attached data
            ["GetAttachedData"] = function(aType, target, owner)
                return clone(getAttributeData(aType, target, owner), true, true)
            end;

            --- Get all targets have attached data of the attribtue
            -- @static
            -- @method  GetAttributeTargets
            -- @owner   attribute
            -- @format  attributeType[, cache]
            -- @param   attributeType               the attribute type
            -- @param   cache                       the cache to save the result
            -- @rformat (cache)                     the cache that contains the targets
            -- @rformat (iter, attr)                without the cache parameter, used in generic for
            ["GetAttributeTargets"] = function(aType, cache)
                local adata         = _AttrTargetData[aType]
                if cache then
                    cache   = type(cache) == "table" and wipe(cache) or {}
                    if adata then for k in pairs, adata do tinsert(cache, k) end end
                    return cache
                elseif adata then
                    return function(self, n)
                        return (next(adata, n))
                    end, aType
                else
                    return fakefunc, aType
                end
            end;

            --- Get all target's owners that have attached data of the attribtue
            -- @static
            -- @method  GetAttributeTargetOwners
            -- @owner   attribute
            -- @format  attributeType[, cache]
            -- @param   attributeType               the attribute type
            -- @param   cache                       the cache to save the result
            -- @rformat (cache)                     the cache that contains the targets
            -- @rformat (iter, attr)                without the cache parameter, used in generic for
            ["GetAttributeTargetOwners"] = function(aType, cache)
                local adata         = _AttrOwnerSubData[aType]
                if cache then
                    cache   = type(cache) == "table" and wipe(cache) or {}
                    if adata then for k in pairs, adata do tinsert(cache, k) end end
                    return cache
                elseif adata then
                    return function(self, n)
                        return (next(adata, n))
                    end, aType
                else
                    return fakefunc, aType
                end
            end;

            --- Whether there are registered attributes unused
            -- @static
            -- @method  HaveRegisteredAttributes
            -- @owner   attribtue
            -- @format  (target, targettype[, stack])
            -- @param   target                      the target
            -- @param   targettype                  the target type
            -- @param   stack                       the stack level
            ["HaveRegisteredAttributes"] = function()
                return #_RegisteredAttrs > 0
            end;

            --- Call a definition function within a standalone attribute system
            -- so it won't use the registered attributes that belong to others.
            -- Normally used in attribute's ApplyAttribute or AttachAttribute
            -- that need create new features with attributes.
            -- @static
            -- @method  IndependentCall
            -- @owner   attribtue
            -- @format  definition[, stack]
            -- @param   definition                  the function to be processed
            -- @param   stack                       the stack level
            ["IndependentCall"] = function(definition, static)
                if type(definition) ~= "function" then
                    error("Usage : attribute.Register(definition) - the definition must be a function", parsestack(stack) + 1)
                end

                tinsert(_RegisteredAttrsStack, _RegisteredAttrs)
                _RegisteredAttrs= _Cache()

                local ok, msg   = pcall(definition)

                _RegisteredAttrs= tremove(_RegisteredAttrsStack) or _Cache()

                if not ok then error(msg, 0) end
            end;

            --- Register the super's inheritable attributes to the target, must be called after
            -- the @attribute.SaveAttributes and before the @attribute.AttachAttributes
            -- @static
            -- @method  Inherit
            -- @owner   attribute
            -- @format  (target, targettype, ...)
            -- @param   target                      the target, maybe class, method, object and etc
            -- @param   targettype                  the flag value of the target's type
            -- @param   ...                         the target's super that used for attribute inheritance
            ["InheritAttributes"] = function(target, targettype, ...)
                local cnt       = select("#", ...)
                if cnt == 0 then return end

                -- Apply the attribute to the target
                Debug("[attribute][InheritAttributes] ==> [%s]%s", _AttrTargetTypes[targettype] or "Unknown", tostring(target))

                local tarAttrs  = _TargetAttrs[target]

                -- Check inheritance
                for i = 1, select("#", ...) do
                    local super = select(i, ...)
                    if super and _AttrTargetInrt[super] then
                        for _, sattr in pairs, _AttrTargetInrt[super] do
                            local aTar = getAttributeInfo(sattr, "AttributeTarget", ATTRTAR_ALL, "number")

                            if aTar == ATTRTAR_ALL or validateFlags(targettype, aTar) then
                                Trace("Inherit attribtue %s", tostring(sattr))
                                tarAttrs = tarAttrs or _Cache()
                                addAttribute(tarAttrs, sattr, true)
                            end
                        end
                    end
                end

                Trace("[attribute][InheritAttributes] <== [%s]%s", _AttrTargetTypes[targettype] or "Unknown", tostring(target))

                _TargetAttrs[target] = tarAttrs
            end;

            --- Use the registered attributes to init the target's definition
            -- @static
            -- @method  InitDefinition
            -- @owner   attribute
            -- @format  (target, targettype, definition, [owner], [name][, stack])
            -- @param   target                      the target, maybe class, method, object and etc
            -- @param   targettype                  the flag value of the target's type
            -- @param   definition                  the definition of the target
            -- @param   owner                       the target's owner, like the class for a method
            -- @param   name                        the target's name if it has owner
            -- @param   stack                       the stack level
            -- @return  definition                  the target's new definition, nil means no change, false means cancel the target's definition, it may be done by the attribute, these may not be supported by the target type
            ["InitDefinition"]  = function(target, targettype, definition, owner, name, stack)
                local tarAttrs  = _TargetAttrs[target]
                if not tarAttrs then return definition end

                stack           = parsestack(stack) + 1

                -- Apply the attribute to the target
                Debug("[attribute][InitDefinition] ==> [%s]%s", _AttrTargetTypes[targettype] or "Unknown", owner and ("[" .. tostring(owner) .. "]" .. name) or tostring(target))

                for i, attr in ipairs, tarAttrs, 0 do
                    local ausage= getAttributeUsage(attr)
                    local apply = getAttributeInfo (attr, "InitDefinition", nil, "function", ausage)

                    -- Apply attribute before the definition
                    if apply then
                        Trace("Call %s.InitDefinition", tostring(attr))

                        local ret = apply(attr, target, targettype, definition, owner, name, stack)
                        if ret ~= nil then definition = ret end
                    end
                end

                Trace("[attribute][InitDefinition] <== [%s]%s", _AttrTargetTypes[targettype] or "Unknown", owner and ("[" .. tostring(owner) .. "]" .. name) or tostring(target))

                return definition
            end;

            --- Register the attribute to be used by the next feature
            -- @static
            -- @method  Register
            -- @owner   attribute
            -- @format  attr[, unique][, stack]
            -- @param   attr                        the attribute to be registered
            -- @param   unique                      whether don't register the attribute if there is another attribute with the same type
            -- @param   stack                       the stack level
            ["Register"]        = function(attr, unique, stack)
                if type(attr) ~= "table" and type(attr) ~= "userdata" then error("Usage : attribute.Register(attr[, unique][, stack]) - the attr is not valid", parsestack(stack) + 1) end
                Debug("[attribute][Register] %s", tostring(attr))
                return addAttribute(_RegisteredAttrs, attr, unique)
            end;

            --- Register attribute target type
            -- @static
            -- @method  RegisterTargetType
            -- @owner   attribtue
            -- @param   name:string                 the target type's name
            -- @return  flag:number                 the target type's flag value
            ["RegisterTargetType"]  = function(name)
                local i             = 1
                while _AttrTargetTypes[i] do i = i * 2 end
                _AttrTargetTypes[i] = name
                Debug("[attribute][RegisterTargetType] %q = %d", name, i)
                return i
            end;

            --- Release the registered attribute of the target
            -- @static
            -- @method  RegisterTargetType
            -- @owner   attribtue
            -- @param   target                      the target, maybe class, method, object and etc
            ["ReleaseTargetAttributes"] = function(target)
                local tarAttrs  = _TargetAttrs[target]
                if not tarAttrs then return else _TargetAttrs[target] = nil end
            end;

            --- Save the current registered attributes to the target
            -- @static
            -- @method  SaveAttributes
            -- @owner   attribtue
            -- @format  (target, targettype[, stack])
            -- @param   target                      the target
            -- @param   targettype                  the target type
            -- @param   stack                       the stack level
            ["SaveAttributes"]  = function(target, targettype, stack)
                if #_RegisteredAttrs  == 0 then return end

                local regAttrs  = _RegisteredAttrs
                _RegisteredAttrs= _Cache()

                Debug("[attribute][SaveAttributes] ==> [%s]%s", _AttrTargetTypes[targettype] or "Unknown", tostring(target))

                for i = #regAttrs, 1, -1 do
                    local attr  = regAttrs[i]
                    local aTar  = getAttributeInfo(attr, "AttributeTarget", ATTRTAR_ALL, "number")

                    if aTar ~= ATTRTAR_ALL and not validateFlags(targettype, aTar) then
                        if _UseWarnInstreadErr then
                            Warn("The attribute %s can't be applied to the [%s]%s", tostring(attr), _AttrTargetTypes[targettype] or "Unknown", tostring(target))
                            tremove(regAttrs, i)
                        else
                            _Cache(regAttrs)
                            error(strformat("The attribute %s can't be applied to the [%s]%s", tostring(attr), _AttrTargetTypes[targettype] or "Unknown", tostring(target)), parsestack(stack) + 1)
                        end
                    end
                end

                Debug("[attribute][SaveAttributes] <== [%s]%s", _AttrTargetTypes[targettype] or "Unknown", tostring(target))

                _TargetAttrs[target] = regAttrs
            end;

            --- Toggle the target, save the old target's attributes to the new one
            -- @static
            -- @method  ToggleTarget
            -- @owner   attribtue
            -- @format  (old, new)
            -- @param   old                         the old target
            -- @param   new                         the new target
            ["ToggleTarget"]    = function(old, new)
                local tarAttrs  = _TargetAttrs[old]
                if tarAttrs and new and new ~= old then
                    _TargetAttrs[old] = nil
                    _TargetAttrs[new] = tarAttrs
                end
            end;

            --- Un-register an attribute
            -- @static
            -- @method  Unregister
            -- @owner   attribtue
            -- @param   attr                        the attribtue to be un-registered
            ["Unregister"]      = function(attr)
                for i, v in ipairs, _RegisteredAttrs, 0 do
                    if v == attr then
                        Debug("[attribute][Unregister] %s", tostring(attr))
                        return tremove(_RegisteredAttrs, i)
                    end
                end
            end;
        },
        __newindex              = readOnly,
    }
end

-------------------------------------------------------------------------------
-- The environment is designed to be private and standalone for codes(Module)
-- or type building(class and etc). It provide features like keyword accessing,
-- namespace management, get/set management and etc.
--
--      -- Module is an environment type for codes works like _G
--      Module "Test" "v1.0.0"
--
--      -- Declare the namespace for the module
--      namespace "NS.Test"
--
--      -- Import other namespaces to the module
--      import "System.Threading"
--
--      -- By using the get/set management we can use attributes for features
--      -- like functions.
--      __Thread__()
--      function DoThreadTask()
--      end
--
--      -- The function with _ENV will be called within a private environment
--      -- where the class A's definition will be processed. The class A also
--      -- will be saved to the namespace NS.Test since its defined in the Test
--      -- Module.
--      class "A" (function(_ENV)
--          -- So the Score's path should be NS.Test.A.Score since it's defined
--          -- in the class A's definition environment whose namespace is the
--          -- class A.
--          enum "Score" { "A", "B", "C", "D" }
--      end)
--
-- @prototype   environment
-- @usage       -- The environment also can be used to call a function within a
--              -- private environment
--              environment(function(_ENV)
--                  import "System.Threading"
--
--                  __Thread__()
--                  function DoTask()
--                  end
--              end)
-------------------------------------------------------------------------------
do
    -----------------------------------------------------------------------
    --                         attribute targets                         --
    -----------------------------------------------------------------------
    ATTRTAR_FUNCTION            = attribute.RegisterTargetType("Function")

    -----------------------------------------------------------------------
    --                         private constants                         --
    -----------------------------------------------------------------------
    -- Environment Special Field
    local ENV_NS_OWNER          = "__PLOOP_ENV_OWNNS"
    local ENV_NS_IMPORTS        = "__PLOOP_ENV_IMPNS"
    local ENV_BASE_ENV          = "__PLOOP_ENV_BSENV"
    local ENV_GLOBAL_CACHE      = "__PLOOP_ENV_GLBCA"

    -----------------------------------------------------------------------
    --                          private storage                          --
    -----------------------------------------------------------------------
    -- Registered Keywords
    local _ContextKeywords      = {}                -- Keywords for environment type
    local _GlobalKeywords       = {}                -- Global keywords
    local _GlobalNS             = {}                -- Global namespaces

    -- Keyword visitor
    local _KeyVisitor                               -- The environment that access the next keyword
    local _AccessKey                                -- The next keyword

    -----------------------------------------------------------------------
    --                          private helpers                          --
    -----------------------------------------------------------------------
    local exportToEnv           = function(env, name, value, stack)
        local tname             = type(name)
        stack                   = stack + 1

        if tname == "number" then
            tname               = type(value)

            if tname == "string" then
                rawset(env, name, environment.GetValue(env, name, true, stack))
            elseif namespace.Validate(value) then
                rawset(env, namespace.GetNamespaceName(value, true), value)
            end
        elseif tname == "string" then
            if value ~= nil then
                rawset(env, name, value)
            else
                rawset(env, name, environment.GetValue(env, name, true, stack))
            end
        elseif namespace.Validate(name) then
            rawset(env, namespace.GetNamespaceName(name, true), value)
        end
    end

    -----------------------------------------------------------------------
    --                             prototype                             --
    -----------------------------------------------------------------------
    environment                 = prototype {
        __tostring              = "environment",
        __index                 = {
            --- Export variables by name or a list of names, those variables are
            -- fetched from the namespaces or base environment
            -- @static
            -- @method  ExportVariables
            -- @owner   environment
            -- @format  (env, name[, stack])
            -- @format  (env, namelist[, stack])
            -- @param   env                         the environment
            -- @param   name                        the variable name or namespace
            -- @param   namelist                    the list or variable names
            -- @param   stack                       the stack level
            ["ExportVariables"]   = function(env, name, stack)
                stack           = parsestack(stack) + 1
                if type(name)  == "table" and getmetatable(name) == nil then
                    for k, v in pairs, name do
                        exportToEnv(env, k, v, stack)
                    end
                else
                    exportToEnv(env, name, nil, stack)
                end
            end;

            --- Get the namespace from the environment
            -- @static
            -- @method  GetNamespace
            -- @owner   environment
            -- @param   env:table                   the environment
            -- @return  ns                          the namespace of the environment
            ["GetNamespace"]    = function(env)
                env = env or getfenv(2)
                return namespace.Validate(type(env) == "table" and rawget(env, ENV_NS_OWNER))
            end;

            --- Get the parent environment from the environment
            -- @static
            -- @method  GetParent
            -- @owner   environment
            -- @param   env:table                   the environment
            -- @return  parentEnv                   the parent of the environment
            ["GetParent"]       = function(env)
                return type(env) == "table" and rawget(env, ENV_BASE_ENV) or nil
            end;

            --- Get the value from the environment based on its namespace and
            -- parent settings(normally be used in __newindex for environment),
            -- the keywords also must be fetched through it.
            -- @static
            -- @method  GetValue
            -- @owner   environment
            -- @format  (env, name, [noautocache][, stack])
            -- @param   env:table                   the environment
            -- @param   name                        the key of the value
            -- @param   noautocache                 true if don't save the value to the environment, the keyword won't be saved
            -- @param   stack                       the stack level
            -- @return  value                       the value of the name in the environment
            ["GetValue"]        = (function()
                local head              = _Cache()
                local body              = _Cache()
                local upval             = _Cache()
                local apis              = _Cache()

                -- Check the keywords
                tinsert(head, "_GlobalKeywords")
                tinsert(upval, _GlobalKeywords)

                tinsert(head, "_ContextKeywords")
                tinsert(upval, _ContextKeywords)

                tinsert(head, "_GlobalNS")
                tinsert(upval, _GlobalNS)

                tinsert(head, "regKeyVisitor")
                tinsert(upval, function(env, keyword) _KeyVisitor, _AccessKey = env, keyword return keyword end)

                uinsert(apis, "type")
                uinsert(apis, "rawget")

                tinsert(body, "")
                tinsert(body, "")
                tinsert(body, [[
                    local getenvvalue
                    getenvvalue = function(env, name, isparent)
                        local value
                ]])

                if PLOOP_PLATFORM_SETTINGS.MULTI_OS_THREAD and not PLOOP_PLATFORM_SETTINGS.MULTI_OS_THREAD_LUA_LOCK_APPLIED then
                    -- Don't cache global variables in the environment to avoid conflict
                    -- The cache should be full-hit during runtime after several operations
                    tinsert(body, [[
                        if isparent then
                            value = rawget(env, "]] .. ENV_GLOBAL_CACHE .. [[")
                            if type(value) == "table" then
                                value = rawget(value, name)
                                if value ~= nil then return value end
                            else
                                value = nil
                            end
                        end
                    ]])
                end

                -- Check current namespace
                tinsert(body, [[
                    local nvalid = namespace.Validate
                    local nsname = namespace.GetNamespaceName
                    local ns = nvalid(rawget(env, "]] .. ENV_NS_OWNER .. [["))
                    if ns then
                        value = name == nsname(ns, true) and ns or ns[name]
                    end
                ]])

                -- Check imported namespaces
                uinsert(apis, "ipairs")
                tinsert(body, [[
                    if value == nil then
                        local imp = rawget(env, "]] .. ENV_NS_IMPORTS .. [[")
                        if type(imp) == "table" then
                            for _, sns in ipairs, imp, 0 do
                                sns = nvalid(sns)
                                if sns then
                                    value = name == nsname(sns, true) and sns or sns[name]
                                    if value ~= nil then break end
                                end
                            end
                        end
                    end
                ]])

                -- Check global namespaces & root namespaces
                tinsert(body, [[
                    if not isparent then
                        if value == nil then
                            for _, sns in ipairs, _GlobalNS, 0 do
                                value = name == nsname(sns, true) and sns or sns[name]
                                if value ~= nil then break end
                            end
                        end

                        if value == nil then
                            value = namespace.GetNamespace(name)
                        end
                    end
                ]])

                -- Check base environment
                uinsert(apis, "_G")
                tinsert(body, [[
                    if value == nil then
                        local parent = rawget(env, "]] .. ENV_BASE_ENV .. [[")
                        if type(parent) == "table" and parent ~= _G then
                            value = rawget(parent, name)
                            if value == nil then
                                value = getenvvalue(parent, name, true)
                            end
                        else
                            value = rawget(_G, name)
                        end
                    end
                ]])

                tinsert(body, [[
                        return value
                    end

                    return function(env, name, noautocache, stack)
                        if type(name) == "string" then
                            local value
                ]])

                if PLOOP_PLATFORM_SETTINGS.MULTI_OS_THREAD and not PLOOP_PLATFORM_SETTINGS.MULTI_OS_THREAD_LUA_LOCK_APPLIED then
                    -- Don't cache global variables in the environment to avoid conflict
                    -- The cache should be full-hit during runtime after several operations
                    tinsert(body, [[
                        value = env["]] .. ENV_GLOBAL_CACHE .. [["][name]
                        if value ~= nil then return value end
                    ]])
                end

                -- Check keywords
                uinsert(apis, "getmetatable")
                tinsert(body, [[
                    value = _GlobalKeywords[name]
                    if not value then
                        local keys = _ContextKeywords[getmetatable(env)]
                        value = keys and keys[name]
                    end
                    if value then
                        return regKeyVisitor(env, value)
                    end
                ]])

                tinsert(body, [[
                    value = getenvvalue(env, name)
                ]])

                if not PLOOP_PLATFORM_SETTINGS.ENV_ALLOW_GLOBAL_VAR_BE_NIL then
                    uinsert(apis, "error")
                    uinsert(apis, "strformat")
                    tinsert(body, [[
                        if value == nil then error(strformat("The global variable %q can't be nil.", name), (stack or 1) + 1) end
                    ]])
                end

                -- Auto-Cache
                tinsert(body, [[
                    if value ~= nil and not noautocache then
                ]])

                if PLOOP_PLATFORM_SETTINGS.MULTI_OS_THREAD and not PLOOP_PLATFORM_SETTINGS.MULTI_OS_THREAD_LUA_LOCK_APPLIED then
                    uinsert(apis, "saveStorage")
                    tinsert(body, [[env["]] .. ENV_GLOBAL_CACHE .. [["] = saveStorage(env["]] .. ENV_GLOBAL_CACHE .. [["], name, value)]])
                    if PLOOP_PLATFORM_SETTINGS.MULTI_OS_THREAD_ENV_AUTO_CACHE_WARN then
                        uinsert(apis, "Warn")
                        uinsert(apis, "tostring")
                        tinsert(body, [[Warn("The [%s] is auto saved to %s, need use 'export{ %q }'", (stack or 1) + 1, name, tostring(env), name)]])
                    end
                else
                    uinsert(apis, "rawset")
                    tinsert(body, [[rawset(env, name, value)]])
                end

                tinsert(body, [[
                            end
                            return value
                        end
                    end
                ]])

                if #head > 0 then
                    body[1] = "local " .. tblconcat(head, ",") .. "= ..."
                end
                if #apis > 0 then
                    local declare = tblconcat(apis, ", ")
                    body[2] = strformat("local %s = %s", declare, declare)
                end

                local func = loadSnippet(tblconcat(body, "\n"), "environment.GetValue")(unpack(upval))

                _Cache(head)
                _Cache(body)
                _Cache(upval)
                _Cache(apis)

                return func
            end)();

            --- Get the environment that visit the given keyword. The visitor
            -- use @environment.GetValue to access the keywords, so the system
            -- know where the keyword is called, this method is normally called
            -- by the keywords.
            -- @static
            -- @method  GetKeywordVisitor
            -- @owner   environment
            -- @param   keyword                     the keyword
            -- @return  visitor                     the keyword visitor(environment)
            ["GetKeywordVisitor"] = function(keyword)
                local visitor
                if _AccessKey  == keyword then visitor = _KeyVisitor end
                _KeyVisitor     = nil
                _AccessKey      = nil
                return visitor
            end;

            --- Import namespace to environment
            -- @static
            -- @method  ImportNamespace
            -- @owner   environment
            -- @format  (env, ns[, stack])
            -- @param   env                         the environment
            -- @param   ns                          the namespace, it can be the namespace itself or its name path
            -- @param   stack                       the stack level
            ["ImportNamespace"] = function(env, ns, stack)
                ns = namespace.Validate(ns)
                if type(env) ~= "table" then error("Usage: environment.ImportNamespace(env, namespace) - the env must be a table", parsestack(stack) + 1) end
                if not ns then error("Usage: environment.ImportNamespace(env, namespace) - The namespace is not provided", parsestack(stack) + 1) end

                local imports   = rawget(env, ENV_NS_IMPORTS)
                if not imports then imports = newStorage(WEAK_VALUE) rawset(env, ENV_NS_IMPORTS, imports) end
                for _, v in ipairs, imports, 0 do if v == ns then return end end
                tinsert(imports, ns)
            end;

            --- Initialize the environment
            -- @static
            -- @method  Initialize
            -- @owner   environment
            -- @param   env                         the environment
            ["Initialize"]      = PLOOP_PLATFORM_SETTINGS.MULTI_OS_THREAD and not PLOOP_PLATFORM_SETTINGS.MULTI_OS_THREAD_LUA_LOCK_APPLIED and function(env)
                if type(env) == "table" then rawset(env, ENV_GLOBAL_CACHE, {}) end
            end or fakefunc;

            --- Register a namespace as global namespace, so it can be accessed
            -- by all environments
            -- @static
            -- @method  RegisterGlobalNamespace
            -- @param   namespace                   the target namespace
            ["RegisterGlobalNamespace"] = function(ns)
                local ns    = namespace.Validate(ns)
                if ns then uinsert(_GlobalNS, ns) end
            end;

            --- Register a context keyword, like property must be used in the
            -- definition of a class or interface.
            -- @static
            -- @method  RegisterContextKeyword
            -- @owner   environment
            -- @format  (ctxType, [key, ]keyword)
            -- @param   ctxType                     the context environment's type
            -- @param   key:string                  the keyword's name, it'd be applied if the keyword is a function
            -- @param   keyword                     the keyword entity
            -- @format  (ctxType, keywords)
            -- @param   keywords:table              a collection of the keywords like : { import = import , class, struct }
            ["RegisterContextKeyword"] = function(ctxType, key, keyword)
                if not ctxType or (type(ctxType) ~= "table" and type(ctxType) ~= "userdata") then
                    error("Usage: environment.RegisterContextKeyword(ctxType, key[, keyword]) - the ctxType isn't valid", 2)
                end
                _ContextKeywords[ctxType] = _ContextKeywords[ctxType] or {}
                local keywords            = _ContextKeywords[ctxType]

                if type(key) == "table" and getmetatable(key) == nil then
                    for k, v in pairs, key do
                        if type(k) ~= "string" then k = tostring(v) end
                        if not keywords[k] and v then keywords[k] = v end
                    end
                else
                    if type(key) ~= "string" then key, keyword= tostring(key), key end
                    if key and not keywords[key] and keyword then keywords[key] = keyword end
                end
            end;

            --- Register a global keyword
            -- @static
            -- @method  RegisterGlobalKeyword
            -- @owner   environment
            -- @format  ([key, ]keyword)
            -- @param   key:string                  the keyword's name, it'd be applied if the keyword is a function
            -- @param   keyword                     the keyword entity
            -- @format  (keywords)
            -- @param   keywords:table              a collection of the keywords like : { import = import , class, struct }
            ["RegisterGlobalKeyword"] = function(key, keyword)
                local keywords      = _GlobalKeywords

                if type(key) == "table" and getmetatable(key) == nil then
                    for k, v in pairs, key do
                        if type(k) ~= "string" then k = tostring(v) end
                        if not keywords[k] and v then keywords[k] = v end
                    end
                else
                    if type(key) ~= "string" then key, keyword = tostring(key), key end
                    if key and not keywords[key] and keyword then keywords[key] = keyword end
                end
            end;

            --- Save the value to the environment, useful to save attribtues for functions
            -- @static
            -- @method  SaveValue
            -- @owner   environment
            -- @format  (env, name, value[, stack])
            -- @param   env                         the environment
            -- @param   name                        the key
            -- @param   value                       the value
            -- @param   stack                       the stack level
            ["SaveValue"]       = function(env, key, value, stack)
                if type(key)   == "string" and type(value) == "function" and attribute.HaveRegisteredAttributes() then
                    stack       = parsestack(stack) + 1
                    attribute.SaveAttributes(value, ATTRTAR_FUNCTION, stack)
                    local final = attribute.InitDefinition(value, ATTRTAR_FUNCTION, value, env, key, stack)
                    if final ~= value then
                        attribute.ToggleTarget(value, final)
                        value   = final
                    end
                    attribute.ApplyAttributes (value, ATTRTAR_FUNCTION, env, key, stack)
                    attribute.AttachAttributes(value, ATTRTAR_FUNCTION, env, key, stack)
                end
                return rawset(env, key, value)
            end;

            --- Set the namespace to the environment
            -- @static
            -- @method  SetNamespace
            -- @owner   environment
            -- @format  (env, ns[, stack])
            -- @param   env                         the environment
            -- @param   ns                          the namespace, it can be the namespace itself or its name path
            -- @param   stack                       the stack level
            ["SetNamespace"]    = function(env, ns, stack)
                if type(env) ~= "table" then error("Usage: environment.SetNamespace(env, namespace) - the env must be a table", parsestack(stack) + 1) end
                rawset(env, ENV_NS_OWNER, namespace.Validate(ns))
            end;

            --- Set the parent environment to the environment
            -- @static
            -- @method  SetParent
            -- @owner   environment
            -- @format  (env, base[, stack])
            -- @param   env                         the environment
            -- @param   base                        the base environment
            -- @param   stack                       the stack level
            ["SetParent"]       = function(env, base, stack)
                if type(env) ~= "table" then error("Usage: environment.SetParent(env, [parentenv]) - the env must be a table", parsestack(stack) + 1) end
                if base and type(base) ~= "table" then error("Usage: environment.SetParent(env, [parentenv]) - the parentenv must be a table", parsestack(stack) + 1) end
                rawset(env, ENV_BASE_ENV, base or nil)
            end;
        },
        __newindex              = readOnly,
        __call                  = function(self, definition)
            local env           = prototype.NewObject(tenvironment)
            environment.Initialize(env)
            if definition then
                return env(definition)
            else
                return env
            end
        end,
    }

    tenvironment                = prototype {
        __index                 = environment.GetValue,
        __newindex              = environment.SaveValue,
        __call                  = function(self, definition)
            if type(definition) ~= "function" then error("Usage: environment(definition) - the definition must be a function", 2) end
            setfenv(definition, self)
            return definition(self)
        end,
    }

    -----------------------------------------------------------------------
    --                             keywords                              --
    -----------------------------------------------------------------------
    -----------------------------------------------------------------------
    -- import namespace to current environment
    --
    -- @keyword     import
    -- @usage       import "System.Threading"
    -----------------------------------------------------------------------
    import                      = function (...)
        local visitor, env, name, _, flag, stack  = getFeatureParams(import, namespace, ...)

        name = namespace.Validate(name)
        if not env  then error("Usage: import(namespace) - The system can't figure out the environment", stack + 1) end
        if not name then error("Usage: import(namespace) - The namespace is not provided", stack + 1) end

        if visitor then
            return environment.ImportNamespace(visitor, name)
        else
            return namespace.ExportNamespace(env, name, flag)
        end
    end

    -----------------------------------------------------------------------
    -- export variables to current environment
    --
    -- @keyword     export
    -- @usage       export { "print", log = "math.log", System.Delegate }
    -----------------------------------------------------------------------
    export                      = function (...)
        local visitor, env, name, definition, flag, stack  = getFeatureParams(export, nil, ...)

        if not visitor  then error("Usage: export(name|namelist) - The system can't figure out the environment", stack + 1) end

        environment.ExportVariables(visitor, name or definition)
    end

    -----------------------------------------------------------------------
    -- get the current environment
    --
    -- @keyword     currentenv
    -----------------------------------------------------------------------
    currentenv                  = function (...)
        return environment.GetKeywordVisitor(currentenv)
    end
end

-------------------------------------------------------------------------------
-- The namespaces are used to organize feature types. Same name features can be
-- saved in different namespaces so there won't be any conflict. Environment
-- can have a root namespace so all features defined in it will be saved to the
-- root namespace, also it can import several other namespaces, features that
-- defined in them can be used in the environment directly.
--
-- @prototype   namespace
-- @usage       -- Normally should be used within private code environment
--              environment(function(_ENV)
--                  namespace "NS.Test"
--
--                  class "A" {}  -- NS.Test.A
--              end)
--
--              -- Also you can use a pure namespace like using environment
--              NS.Test (function(_ENV)
--                  class "A" {}  -- NS.Test.A
--              end)
-------------------------------------------------------------------------------
do
    -----------------------------------------------------------------------
    --                         attribute targets                         --
    -----------------------------------------------------------------------
    ATTRTAR_NAMESPACE           = attribute.RegisterTargetType("Namespace")

    -----------------------------------------------------------------------
    --                         private constants                         --
    -----------------------------------------------------------------------
    local FLD_NS_SUBNS          = "__PLOOP_NS_SUBNS"
    local FLD_NS_NAME           = "__PLOOP_NS_NAME"

    -----------------------------------------------------------------------
    --                          private storage                          --
    -----------------------------------------------------------------------
    local _NSTree               = PLOOP_PLATFORM_SETTINGS.UNSAFE_MODE
                                    and setmetatable({}, {__index = function(_, ns) if type(ns) == "table" then return rawget(ns, FLD_NS_SUBNS) end end})
                                    or  newStorage(WEAK_KEY)
    local _NSName               = PLOOP_PLATFORM_SETTINGS.UNSAFE_MODE
                                    and setmetatable({}, {__index = function(_, ns) if type(ns) == "table" then return rawget(ns, FLD_NS_NAME) end end})
                                    or  newStorage(WEAK_KEY)
    local _ValidTypeCombine     = newStorage(WEAK_KEY)
    local _UnmSubTypeMap        = newStorage(WEAK_ALL)

    -----------------------------------------------------------------------
    --                          private helpers                          --
    -----------------------------------------------------------------------
    local getNamespace          = function(root, path)
        if type(root)  == "string" then
            root, path  = ROOT_NAMESPACE, root
        elseif root    == nil then
            root        = ROOT_NAMESPACE
        end

        if _NSName[root] ~= nil and type(path) == "string" then
            path            = strgsub(path, "%s+", "")
            local iter      = strgmatch(path, "[%P_]+")
            local subname   = iter()

            while subname do
                local nodes = _NSTree[root]
                root        = nodes and nodes[subname]
                if not root then return end

                local nxt   = iter()
                if not nxt  then return root end

                subname     = nxt
            end
        end
    end

    local getValidatedNS        = function(target)
        if type(target) == "string" then return getNamespace(target) end
        return _NSName[target] ~= nil and target or nil
    end

    local saveSubNamespace      = PLOOP_PLATFORM_SETTINGS.UNSAFE_MODE
                                    and function(root, name, subns) rawset(root, FLD_NS_SUBNS, saveStorage(rawget(root, FLD_NS_SUBNS) or {}, name, subns)) end
                                    or  function(root, name, subns) _NSTree = saveStorage(_NSTree, root, saveStorage(_NSTree[root] or {}, name, subns)) end

    local saveNamespaceName     = PLOOP_PLATFORM_SETTINGS.UNSAFE_MODE
                                    and function(ns, name) rawset(ns, FLD_NS_NAME, name) rawset(ns, FLD_NS_SUBNS, false) end
                                    or  function(ns, name) _NSName = saveStorage(_NSName, ns, name) end

    -----------------------------------------------------------------------
    --                             prototype                             --
    -----------------------------------------------------------------------
    namespace                   = prototype {
        __tostring              = "namespace",
        __index                 = {
            --- Export a namespace and its children to an environment
            -- @static
            -- @method  ExportNamespace
            -- @owner   namespace
            -- @format  (env, ns[, override][, stack])
            -- @param   env                         the environment
            -- @param   ns                          the namespace
            -- @param   override                    whether override the existed value in the environment, Default false
            -- @param   stack                       the stack level
            ["ExportNamespace"] = function(env, ns, override, stack)
                if type(env)   ~= "table" then error("Usage: namespace.ExportNamespace(env, namespace[, override]) - the env must be a table", parsestack(stack) + 1) end
                ns  = getValidatedNS(ns)
                if not ns then error("Usage: namespace.ExportNamespace(env, namespace[, override]) - The namespace is not provided", parsestack(stack) + 1) end

                local nsname    = _NSName[ns]
                if nsname then
                    nsname      = strmatch(nsname, "[%P_]+$")
                    if override or rawget(env, nsname) == nil then rawset(env, nsname, ns) end
                end

                local nodes = _NSTree[ns]
                if nodes then
                    for name, sns in pairs, nodes do
                        if override or rawget(env, name) == nil then rawset(env, name, sns) end
                    end
                end
            end;

            --- Get the namespace by path
            -- @static
            -- @method  GetNamespace
            -- @owner   namespace
            -- @format  ([root, ]path)
            -- @param   root                        the root namespace
            -- @param   path:string                 the namespace path
            -- @return  ns                          the namespace
            ["GetNamespace"]    = getNamespace;

            --- Get the namespace's path
            -- @static
            -- @method  GetNamespaceName
            -- @owner   namespace
            -- @format  (ns[, lastOnly])
            -- @param   ns                          the namespace
            -- @parma   lastOnly                    whether only the last name of the namespace's path
            -- @return  string                      the path of the namespace or the name of it if lastOnly is true
            ["GetNamespaceName"]= function(ns, onlyLast)
                local name = _NSName[ns]
                return name and (onlyLast and strmatch(name, "[%P_]+$") or name) or "Anonymous"
            end;

            --- Save feature to the namespace
            -- @static
            -- @method  SaveNamespace
            -- @owner   namespace
            -- @format  ([root, ]path, feature[, stack])
            -- @param   root                        the root namespace
            -- @param   path:string                 the path of the feature
            -- @param   feature                     the feature, must be table or userdata
            -- @param   stack                       the stack level
            -- @return  feature                     the feature itself
            ["SaveNamespace"]   = function(root, path, feature, stack)
                if type(root)  == "string" then
                    root, path, feature, stack = ROOT_NAMESPACE, root, path, feature
                elseif root    == nil then
                    root        = ROOT_NAMESPACE
                else
                    root        = getValidatedNS(root)
                end

                stack           = parsestack(stack) + 1

                if root == nil then
                    error("Usage: namespace.SaveNamespace([root, ]path, feature[, stack]) - the root must be namespace", stack)
                end
                if type(path) ~= "string" or strtrim(path) == "" then
                    error("Usage: namespace.SaveNamespace([root, ]path, feature[, stack]) - the path must be string", stack)
                else
                    path        = strgsub(path, "%s+", "")
                end
                if type(feature) ~= "table" and type(feature) ~= "userdata" then
                    error("Usage: namespace.SaveNamespace([root, ]path, feature[, stack]) - the feature should be userdata or table", stack)
                end

                if _NSName[feature] ~= nil then
                    local epath = _Cache()
                    if _NSName[root] then tinsert(epath, _NSName[root]) end
                    path:gsub("[%P_]+", function(name) tinsert(epath, name) end)
                    if tblconcat(epath, ".") == _NSName[feature] then
                        return feature
                    else
                        error("Usage: namespace.SaveNamespace([root, ]path, feature[, stack]) - already registered as " .. (_NSName[feature] or "Anonymous"), stack)
                    end
                end

                local iter      = strgmatch(path, "[%P_]+")
                local subname   = iter()

                while subname do
                    local nodes = _NSTree[root]
                    local subns = nodes and nodes[subname]
                    local nxt   = iter()

                    if not nxt then
                        if subns then
                            if subns == feature then return feature end
                            error("Usage: namespace.SaveNamespace([root, ]path, feature[, stack]) - the namespace path has already be used by others", stack)
                        else
                            saveNamespaceName(feature, _NSName[root] and (_NSName[root] .. "." .. subname) or subname)
                            saveSubNamespace(root, subname, feature)
                        end
                    elseif not subns then
                        subns = prototype.NewProxy(tnamespace)

                        saveNamespaceName(subns, _NSName[root] and (_NSName[root] .. "." .. subname) or subname)
                        saveSubNamespace(root, subname, subns)
                    end

                    root, subname = subns, nxt
                end

                return feature
            end;

            --- Save anonymous namespace, anonymous namespace also can be used
            -- as new root of another namespace tree.
            -- @static
            -- @method  SaveAnonymousNamespace
            -- @owner   namespace
            -- @param   feature                     the feature, must be table or userdata
            -- @param   stack                       the stack level
            ["SaveAnonymousNamespace"] = function(feature, stack)
                stack           = parsestack(stack) + 1
                if type(feature) ~= "table" and type(feature) ~= "userdata" then
                    error("Usage: namespace.SaveAnonymousNamespace(feature[, stack]) - the feature should be userdata or table", stack)
                end
                if _NSName[feature] then
                    error("Usage: namespace.SaveAnonymousNamespace(feature[, stack]) - the feature already registered as " .. _NSName[feature], stack)
                end
                saveNamespaceName(feature, false)
            end;

            --- Whether the target is a namespace
            -- @static
            -- @method  Validate
            -- @owner   namespace
            -- @param   target                      the query feature
            -- @return  target                      nil if not namespace
            ["Validate"]        = getValidatedNS;
        },
        __newindex              = readOnly,
        __call                  = function(self, ...)
            local visitor, env, target, _, flag, stack = getFeatureParams(namespace, namespace, ...)
            stack               = stack + 1

            if not env then error("Usage: namespace([env, ]path[, noset][, stack]) - the system can't figure out the environment", stack) end

            if target ~= nil then
                if type(target) == "string" then
                    local ns    = getNamespace(target)
                    if not ns then
                        ns = prototype.NewProxy(tnamespace)
                        attribute.SaveAttributes(ns, ATTRTAR_NAMESPACE, stack)
                        namespace.SaveNamespace(target, ns, stack)
                        attribute.AttachAttributes(ns, ATTRTAR_NAMESPACE, nil, nil, stack)
                    end
                    target = ns
                else
                    target = Validate(target)
                end

                if not target then error("Usage: namespace([env, ]path[, noset][, stack]) - the system can't figure out the namespace", stack) end
            end

            if not flag then
                if visitor then
                    environment.SetNamespace(visitor, target)
                elseif env and env ~= visitor then
                    environment.SetNamespace(env, target)
                    namespace.ExportNamespace(env, target)
                end
            end

            return target
        end,
    }

    -- default type for namespace
    tnamespace                  = prototype {
        __index                 = namespace.GetNamespace,
        __newindex              = readOnly,
        __tostring              = namespace.GetNamespaceName,
        __metatable             = namespace,
        __concat                = function (a, b) return tostring(a) .. tostring(b) end,
        __call                  = function(self, definition)
            local env           = prototype.NewObject(tenvironment)
            environment.Initialize(env)
            environment.SetNamespace(env, self)
            if definition then
                return env(definition)
            else
                return env
            end
        end,
        __add                   = function(a, b)
            local comb      = _ValidTypeCombine[a] and _ValidTypeCombine[a][b] or _ValidTypeCombine[b] and _ValidTypeCombine[b][a]
            if comb then return comb end

            local valida    = getprototypemethod(a, "ValidateValue")
            local validb    = getprototypemethod(a, "ValidateValue")

            if not valida or not validb then
                error("the both value of the addition must be validation type", 2)
            end

            local isimmua   = getobjectvalue(a, "IsImmutable")
            local isimmub   = getobjectvalue(b, "IsImmutable")
            local isseala   = getobjectvalue(a, "IsSealed")
            local issealb   = getobjectvalue(b, "IsSealed")
            local aname     = _NSName[a]
            local bname     = _NSName[b]
            local cname     = false
            local msg       = "the %s don't meet the requirement"

            if aname and bname then
                if aname:match("^%-") then aname = "(" .. aname .. ")" end
                if bname:match("^%-") then bname = "(" .. bname .. ")" end
                cname       = aname .. " | " .. bname
                msg         = "the %s must be value of " .. cname
            end

            __Sealed__()
            local strt      = struct {
                function (val, onlyvalid)
                    local _, err = valida(a, val, true)
                    if not err then return end
                    _, err = validb(b, val, true)
                    if not err then return end
                    return onlyvalid or msg
                end,
                __init      = not (isimmua and isimmub and isseala and issealb) and function(val)
                    local ret, err = valida(a, val)
                    if not err then return ret end
                    ret, err = validb(b, val)
                    if not err then return ret end
                end or nil,
            }

            local comb      = _ValidTypeCombine[a] or newStorage(WEAK_ALL)
            comb[b]         = strt
            _ValidTypeCombine[a] = comb

            saveNamespaceName(strt, cname)

            return strt
        end,
        __unm                   = function(self)
            local issubtype     = getprototypemethod(self, "IsSubType")
            if not issubtype then
                error("the type's prototype don't support 'IsSubType' check")
            end

            if _UnmSubTypeMap[self] then return _UnmSubTypeMap[self] end

            local sname         = _NSName[self]
            local msg           = sname and ("the %s must be a sub type of " .. sname) or "the %s don't meet the requirement"

            __Sealed__() __Default__(self)
            _UnmSubTypeMap[self]= struct {
                function (val, onlyvalid)
                    return not issubtype(val, self) and (onlyvalid or msg) or nil
                end
            }

            saveNamespaceName(_UnmSubTypeMap[self], sname and ("-" .. sname) or false)

            return _UnmSubTypeMap[self]
        end,
    }

    -----------------------------------------------------------------------
    --                            Initialize                             --
    -----------------------------------------------------------------------
    ROOT_NAMESPACE              = prototype.NewProxy(tnamespace)
    namespace.SaveAnonymousNamespace(ROOT_NAMESPACE)
end

-------------------------------------------------------------------------------
-- An enumeration is a data type consisting of a set of named values called
-- elements, The enumerator names are usually identifiers that behave as
-- constants.
--
-- To define an enum within the PLoop, the syntax is
--
--      enum "Name" { -- key-value pairs }
--
-- In the table, for each key-value pair, if the key is string, the key would
-- be used as the element's name and the value is the element's value. If the
-- key is a number and the value is string, the value would be used as both the
-- element's name and value, othwise the key-value pair will be ignored.
--
-- Use enumeration[elementname] to fetch or validate the enum element's value,
-- also can use enumeration(value) to fetch the element name from value. Here
-- is an example :
--
--      enum "Direction" { North = 1, East = 2, South = 3, West = 4 }
--      print(Direction.South) -- 3
--      print(Direction[3])    -- 3
--      print(Direction.NoDir) -- nil
--
--      print(Direction(3))    -- South
--
-- @prototype   enum
-------------------------------------------------------------------------------
do
    -----------------------------------------------------------------------
    --                         attribute targets                         --
    -----------------------------------------------------------------------
    ATTRTAR_ENUM                = attribute.RegisterTargetType("Enum")

    -----------------------------------------------------------------------
    --                         private constants                         --
    -----------------------------------------------------------------------
    -- FEATURE MODIFIER
    local MOD_SEALED_ENUM       = newflags(true)    -- SEALED
    local MOD_FLAGS_ENUM        = newflags()        -- FLAGS
    local MOD_NOT_FLAGS         = newflags()        -- NOT FLAG

    -- FIELD INDEX
    local FLD_ENUM_MOD          = 0                 -- FIELD MODIFIER
    local FLD_ENUM_ITEMS        = 1                 -- FIELD ENUMERATIONS
    local FLD_ENUM_CACHE        = 2                 -- FIELD CACHE : VALUE -> NAME
    local FLD_ENUM_ERRMSG       = 3                 -- FIELD ERROR MESSAGE
    local FLD_ENUM_MAXVAL       = 4                 -- FIELD MAX VALUE(FOR FLAGS)
    local FLD_ENUM_DEFAULT      = 5                 -- FIELD DEFAULT

    -- Flags
    local FLG_FLAGS_ENUM        = newflags(true)

    -- UNSAFE FIELD
    local FLD_ENUM_META         = "__PLOOP_ENUM_META"

    -----------------------------------------------------------------------
    --                          private storage                          --
    -----------------------------------------------------------------------
    local _EnumInfo             = PLOOP_PLATFORM_SETTINGS.UNSAFE_MODE
                                    and setmetatable({}, {__index = function(_, e) return type(e) == "table" and rawget(e, FLD_ENUM_META) or nil end})
                                    or  newStorage(WEAK_KEY)

    -- BUILD CACHE
    local _EnumBuilderInfo      = newStorage(WEAK_KEY)
    local _EnumValidMap         = {}

    -----------------------------------------------------------------------
    --                          private helpers                          --
    -----------------------------------------------------------------------
    local getEnumTargetInfo     = function (target)
        local info  = _EnumBuilderInfo[target]
        if info then return info, true else return _EnumInfo[target], false end
    end

    local saveEnumMeta          = PLOOP_PLATFORM_SETTINGS.UNSAFE_MODE
                                    and function (e, meta) rawset(e, FLD_ENUM_META, meta) end
                                    or  function (e, meta) _EnumInfo = saveStorage(_EnumInfo, e, meta) end

    -----------------------------------------------------------------------
    --                             prototype                             --
    -----------------------------------------------------------------------
    enum                        = prototype {
        __tostring              = "enum",
        __index                 = {
            --- Add key-value pair to the enumeration
            -- @static
            -- @method  AddElement
            -- @owner   enum
            -- @format  (enumeration, key, value[, stack])
            -- @param   enumeration                 the enumeration
            -- @param   key                         the element name
            -- @param   value                       the element value
            -- @param   stack                       the stack level
            ["AddElement"]      = function(target, key, value, stack)
                local info, def = getEnumTargetInfo(target)
                stack           = parsestack(stack) + 1

                if info then
                    if not def then error(strformat("Usage: enum.AddElement(enumeration, key, value[, stack]) - The %s's definition is finished", tostring(target)), stack) end
                    if type(key) ~= "string" then error("Usage: enum.AddElement(enumeration, key, value[, stack]) - The key must be a string", stack) end

                    for k, v in pairs, info[FLD_ENUM_ITEMS] do
                        if k == key then
                            if v == value then return end
                            error("Usage: enum.AddElement(enumeration, key, value[, stack]) - The key already existed", stack)
                        elseif v == value then
                            error("Usage: enum.AddElement(enumeration, key, value[, stack]) - The value already existed", stack)
                        end
                    end

                    info[FLD_ENUM_ITEMS][key] = value
                else
                    error("Usage: enum.AddElement(enumeration, key, value[, stack]) - The enumeration is not valid", stack)
                end
            end;

            --- Begin the enumeration's definition
            -- @static
            -- @method  BeginDefinition
            -- @owner   enum
            -- @format  (enumeration[, stack])
            -- @param   enumeration                 the enumeration
            -- @param   stack                       the stack level
            ["BeginDefinition"] = function(target, stack)
                stack           = parsestack(stack) + 1
                target          = enum.Validate(target)
                if not target then error("Usage: enum.BeginDefinition(enumeration[, stack]) - the enumeration not existed", stack) end

                local info      = _EnumInfo[target]

                -- if info and validateFlags(MOD_SEALED_ENUM, info[FLD_ENUM_MOD]) then error(strformat("Usage: enum.BeginDefinition(enumeration[, stack]) - The %s is sealed, can't be re-defined", tostring(target)), stack) end
                if _EnumBuilderInfo[target] then error(strformat("Usage: enum.BeginDefinition(enumeration[, stack]) - The %s's definition has already begun", tostring(target)), stack) end

                _EnumBuilderInfo = saveStorage(_EnumBuilderInfo, target, info and validateFlags(MOD_SEALED_ENUM, info[FLD_ENUM_MOD]) and tblclone(info, {}, true, true) or {
                    [FLD_ENUM_MOD    ]  = 0,
                    [FLD_ENUM_ITEMS  ]  = {},
                    [FLD_ENUM_CACHE  ]  = {},
                    [FLD_ENUM_ERRMSG ]  = "%s must be a value of [" .. tostring(target) .."]",
                    [FLD_ENUM_MAXVAL ]  = false,
                    [FLD_ENUM_DEFAULT]  = nil,
                })

                attribute.SaveAttributes(target, ATTRTAR_ENUM, stack)
            end;

            --- End the enumeration's definition
            -- @static
            -- @method  EndDefinition
            -- @owner   enum
            -- @format  (enumeration[, stack])
            -- @param   enumeration                 the enumeration
            -- @param   stack                       the stack level
            ["EndDefinition"]   = function(target, stack)
                local ninfo     = _EnumBuilderInfo[target]
                if not ninfo then return end

                stack           = parsestack(stack) + 1

                attribute.ApplyAttributes(target, ATTRTAR_ENUM, nil, nil, stack)

                _EnumBuilderInfo = saveStorage(_EnumBuilderInfo, target, nil)

                local enums = ninfo[FLD_ENUM_ITEMS]
                local cache = wipe(ninfo[FLD_ENUM_CACHE])

                for k, v in pairs, enums do cache[v] = k end

                -- Check Flags Enumeration
                if validateFlags(MOD_FLAGS_ENUM, ninfo[FLD_ENUM_MOD]) then
                    -- Mark the max value
                    local max = 1
                    for k, v in pairs, enums do
                        while type(v) == "number" and v >= max do max = max * 2 end
                    end

                    ninfo[FLD_ENUM_MAXVAL]  = max - 1
                else
                    ninfo[FLD_ENUM_MAXVAL]  = false
                    ninfo[FLD_ENUM_MOD]     = turnOnFlags(MOD_NOT_FLAGS, ninfo[FLD_ENUM_MOD])
                end

                -- Save as new enumeration's info
                saveEnumMeta(target, ninfo)

                -- Check Default
                if ninfo[FLD_ENUM_DEFAULT] ~= nil then
                    ninfo[FLD_ENUM_DEFAULT] = enum.ValidateValue(target, ninfo[FLD_ENUM_DEFAULT])
                end

                attribute.AttachAttributes(target, ATTRTAR_ENUM, nil, nil, stack)

                return target
            end;

            --- Get the default value from the enumeration
            -- @static
            -- @method  GetDefault
            -- @owner   enum
            -- @param   enumeration                 the enumeration
            -- @return  default                     the default value
            ["GetDefault"]      = function(target)
                local info      = getEnumTargetInfo(target)
                return info and info[FLD_ENUM_DEFAULT]
            end;

            --- Get the elements from the enumeration
            -- @static
            -- @method  GetEnumValues
            -- @owner   enum
            -- @format  (enumeration[, cache])
            -- @param   enumeration                 the enumeration
            -- @param   cache                       the table used to cache those elements
            -- @rformat (iter, enum)                If cache is nil, the iterator will be returned
            -- @rformat (cache)                     the cache table if used
            ["GetEnumValues"]   = function(target, cache)
                local info      = _EnumInfo[target]
                if info then
                    if cache then
                        return tblclone(info[FLD_ENUM_ITEMS], type(cache) == "table" and wipe(cache) or {})
                    else
                        info    = info[FLD_ENUM_ITEMS]
                        return function(self, key) return next(info, key) end, target
                    end
                end
            end;

            --- Whether the enumeration element values only are flags
            -- @static
            -- @method  IsFlagsEnum
            -- @owner   enum
            -- @param   enumeration                 the enumeration
            -- @return  boolean                     true if the enumeration element values only are flags
            ["IsFlagsEnum"]     = function(target)
                local info      = getEnumTargetInfo(target)
                return info and validateFlags(MOD_FLAGS_ENUM, info[FLD_ENUM_MOD]) or false
            end;

            --- Whether the enum's value is immutable through the validation, always true.
            -- @static
            -- @method  IsImmutable
            -- @owner   enum
            -- @param   enumeration                 the enumeration
            -- @return  true
            ["IsImmutable"]     = function(target) return true end;

            --- Whether the enumeration is sealed, so can't be re-defined
            -- @static
            -- @method  IsSealed
            -- @owner   enum
            -- @param   enumeration                 the enumeration
            -- @return  boolean                     true if the enumeration is sealed
            ["IsSealed"]        = function(target)
                local info      = getEnumTargetInfo(target)
                return info and validateFlags(MOD_SEALED_ENUM, info[FLD_ENUM_MOD]) or false
            end;

            --- Whether the enumeration is sub-type of others, always false, needed by struct system
            -- @static
            -- @method  IsSubType
            -- @owner   enum
            -- @param   enumeration                 the enumeration
            -- @param   super                       the super type
            -- @return  false
            ["IsSubType"]       = function() return false end;

            --- Parse the element value to element name
            -- @static
            -- @method  Parse
            -- @owner   enum
            -- @format  (enumeration, value[, cache])
            -- @param   enumeration                 the enumeration
            -- @param   value                       the value
            -- @param   cache                       the table used to cache the result, only used when the enumeration is flag enum
            -- @rformat (name)                      only if the enumeration is not flags enum
            -- @rformat (iter, enum)                If cache is nil and the enumeration is flags enum, the iterator will be returned
            -- @rformat (cache)                     if the cache existed and the enumeration is flags enum
            ["Parse"]           = function(target, value, cache)
                local info      = _EnumInfo[target]
                if info then
                    local ecache= info[FLD_ENUM_CACHE]

                    if info[FLD_ENUM_MAXVAL] then
                        if cache then
                            local ret = type(cache) == "table" and wipe(cache) or {}

                            if type(value) == "number" and floor(value) == value and value >= 0 and value <= info[FLD_ENUM_MAXVAL] then
                                if value > 0 then
                                    local ckv = 1

                                    while ckv <= value and ecache[ckv] do
                                        if validateFlags(ckv, value) then ret[ecache[ckv]] = ckv end
                                        ckv = ckv * 2
                                    end
                                elseif value == 0 and ecache[0] then
                                    ret[ecache[0]] = 0
                                end
                            end

                            return ret
                        elseif type(value) == "number" and floor(value) == value and value >= 0 and value <= info[FLD_ENUM_MAXVAL] then
                            if value == 0 then
                                return function(self, key) if not key then return ecache[0], 0 end end, target
                            else
                                local ckv = 1
                                return function(self, key)
                                    while ckv <= value and ecache[ckv] do
                                        local v = ckv
                                        ckv = ckv * 2
                                        if validateFlags(v, value) then return ecache[v], v end
                                    end
                                end
                            end
                        else
                            return fakefunc, target
                        end
                    else
                        return ecache[value]
                    end
                end
            end;

            --- Set the enumeration's default value
            -- @static
            -- @method  SetDefault
            -- @owner   enum
            -- @format  (enumeration, default[, stack])
            -- @param   enumeration                 the enumeration
            -- @param   default                     the default value or name
            -- @param   stack                       the stack level
            ["SetDefault"]      = function(target, default, stack)
                local info, def = getEnumTargetInfo(target)
                stack           = parsestack(stack) + 1

                if info then
                    if not def then error(strformat("Usage: enum.SetDefault(enumeration, default[, stack]) - The %s's definition is finished", tostring(target)), stack) end
                    info[FLD_ENUM_DEFAULT] = default
                else
                    error("Usage: enum.SetDefault(enumeration, default[, stack]) - The enumeration is not valid", stack)
                end
            end;

            --- Set the enumeration as flags enum
            -- @static
            -- @method  SetFlagsEnum
            -- @owner   enum
            -- @format  (enumeration[, stack])
            -- @param   enumeration                 the enumeration
            -- @param   stack                       the stack level
            ["SetFlagsEnum"]    = function(target, stack)
                local info, def = getEnumTargetInfo(target)
                stack           = parsestack(stack) + 1

                if info then
                    if not validateFlags(MOD_FLAGS_ENUM, info[FLD_ENUM_MOD]) then
                        if not def then error(strformat("Usage: enum.SetFlagsEnum(enumeration[, stack]) - The %s's definition is finished", tostring(target)), stack) end
                        if validateFlags(MOD_NOT_FLAGS, info[FLD_ENUM_MOD]) then error(strformat("Usage: enum.SetFlagsEnum(enumeration[, stack]) - The %s is defined as non-flags enumeration", tostring(target)), stack) end
                        info[FLD_ENUM_MOD] = turnOnFlags(MOD_FLAGS_ENUM, info[FLD_ENUM_MOD])
                    end
                else
                    error("Usage: enum.SetFlagsEnum(enumeration[, stack]) - The enumeration is not valid", stack)
                end
            end;

            --- Seal the enumeration, so it can't be re-defined
            -- @static
            -- @method  SetSealed
            -- @owner   enum
            -- @format  (enumeration[, stack])
            -- @param   enumeration                 the enumeration
            -- @param   stack                       the stack level
            ["SetSealed"]       = function(target, stack)
                local info      = getEnumTargetInfo(target)

                if info then
                    if not validateFlags(MOD_SEALED_ENUM, info[FLD_ENUM_MOD]) then
                        info[FLD_ENUM_MOD] = turnOnFlags(MOD_SEALED_ENUM, info[FLD_ENUM_MOD])
                    end
                else
                    error("Usage: enum.SetSealed(enumeration[, stack]) - The enumeration is not valid", parsestack(stack) + 1)
                end
            end;

            --- Whether the check value contains the target flag value
            -- @static
            -- @method  ValidateFlags
            -- @owner   enum
            -- @param   target                      the target value only should be 2^n
            -- @param   check                       the check value
            -- @param   boolean                     true if the check value contains the target value
            -- @usage   print(enum.ValidateFlags(4, 7)) -- true : 7 = 1 + 2 + 4
            ["ValidateFlags"]   = validateFlags;

            --- Whether the value is the enumeration's element's name or value
            -- @static
            -- @method  ValidateValue
            -- @owner   enum
            -- @format  (enumeration, value[, onlyvalid])
            -- @param   enumeration                 the enumeration
            -- @param   value                       the value
            -- @param   onlyvalid                   if true use true instead of the error message
            -- @return  value                       the element value, nil if not pass the validation
            -- @return  errormessage                the error message if not pass
            ["ValidateValue"]   = function(target, value, onlyvalid)
                local info      = _EnumInfo[target]
                if info then
                    if info[FLD_ENUM_CACHE][value] then return value end

                    local maxv  = info[FLD_ENUM_MAXVAL]
                    if maxv and type(value) == "number" and floor(value) == value and value > 0 and value <= maxv then
                        return value
                    end

                    return nil, onlyvalid or info[FLD_ENUM_ERRMSG]
                else
                    error("Usage: enum.ValidateValue(enumeration, value) - The enumeration is not valid", 2)
                end
            end;

            --- Whether the value is an enumeration
            -- @static
            -- @method  Validate
            -- @owner   enum
            -- @param   enumeration                 the enumeration
            -- @return  enumeration                 nil if not pass the validation
            ["Validate"]        = function(target)
                return getmetatable(target) == enum and target or nil
            end;
        },
        __newindex              = readOnly,
        __call                  = function(self, ...)
            local visitor, env, target, definition, flag, stack  = getTypeParams(enum, tenum, ...)
            if not target then
                error("Usage: enum([env, ][name, ][definition][, stack]) - the enumeration type can't be created", stack + 1)
            elseif definition ~= nil and type(definition) ~= "table" then
                error("Usage: enum([env, ][name, ][definition][, stack]) - the definition should be a table", stack + 1)
            end

            stack = stack + 1

            if visitor then
                environment.ImportNamespace(visitor, target)
            end

            enum.BeginDefinition(target, stack)

            Debug("[enum] %s created", stack, tostring(target))

            local builder = prototype.NewObject(enumbuilder)
            environment.SetNamespace(builder, target)

            if definition then
                builder(definition, stack)
                return target
            else
                return builder
            end
        end,
    }

    tenum                       = prototype (tnamespace, {
        __index                 = function(self, key) return _EnumInfo[self][FLD_ENUM_ITEMS][key] end,
        __call                  = enum.Parse,
        __metatable             = enum,
    })

    enumbuilder                 = prototype {
        __index                 = writeOnly,
        __newindex              = readOnly,
        __call                  = function(self, definition, stack)
            stack               = parsestack(stack) + 1
            if type(definition) ~= "table" then error("Usage: enum([env, ][name, ][stack]) {...} - The definition table is missing", stack) end

            local owner = environment.GetNamespace(self)
            if not owner then error("The enumeration can't be found", stack) end
            if not _EnumBuilderInfo[owner] then error(strformat("The %s's definition is finished", tostring(owner)), stack) end

            local final = attribute.InitDefinition(owner, ATTRTAR_ENUM, definition, nil, nil, stack)

            if type(final) == "table" then
                definition      = final
            end

            for k, v in pairs, definition do
                if type(k) == "string" then
                    enum.AddElement(owner, k, v, stack)
                elseif type(v) == "string" then
                    enum.AddElement(owner, v, v, stack)
                end
            end

            enum.EndDefinition(owner, stack)
            return owner
        end,
    }
end

-------------------------------------------------------------------------------
-- The structures are types for basic and complex organized datas and also the
-- data contracts for value validation. There are three struct types:
--
--  i. Custom    The basic data types like number, string and more advanced
--          types like nature number. Take the Number as an example:
--
--                  struct "Number" (function(_ENV)
--                      function Number(value)
--                          return type(value) ~= "number" and "the %s must be number, got " .. type(value)
--                      end
--                  end)
--
--                  v = Number(true)  -- Error : the value must be number, got boolean
--
--              Unlike the enumeration, the structure's definition is a little
--          complex, the definition body is a function with _ENV as its first
--          parameter, the pattern is designed to make sure the PLoop works
--          with Lua 5.1 and all above versions. The code in the body function
--          will be processed in a private context used to define the struct.
--
--              The function with the struct's name is the validator, also you
--          can use `__valid` instead of the struct's name(There are anonymous
--          structs). The validator would be called with the target value, if
--          the return value is non-false, that means the target value can't
--          pass the validation, normally the return value should be an error
--          message, the `%s` in the message'll be replaced by words based on
--          where it's used, if the return value is true, the system would
--          generte an error message for it.
--
--              If the struct has only the validator, it's an immutable struct
--          that won't modify the validated value. We also need mutable struct
--          like Boolean :
--
--                  struct "Boolean" (function(_ENV)
--                      function __init(value)
--                          return value and true or fale
--                      end
--                  end)
--
--                  print(Boolean(1))  -- true
--
--              The function named `__init` is the initializer, it's used to
--          modify the target value, if the return value is non-nil, it'll be
--          used as the new value of the target.
--
--              The struct can have one base struct so it will inherit the base
--          struct's validator and initializer, the base struct's validator and
--          initializer should be called before the struct's own:
--
--                  struct "Integer" (function(_ENV)
--                      __base = Number
--
--                      local floor = math.floor
--
--                      function Integer(value)
--                          return floor(value) ~= value and "the %s must be integer"
--                      end
--                  end)
--
--                  v = Integer(true)  -- Error : the value must be number, got boolean
--                  v = Integer(1.23)  -- Error : the value must be integer
--
--
-- ii. Member   The member structure represent tables with fixed fields of
--          certain types. Take an example to start:
--
--                  struct "Location" (function(_ENV)
--                      x = Number
--                      y = Number
--                  end)
--
--                  loc = Location{ x = "x" }    -- Error: Usage: Location(x, y) - x must be number
--                  loc = Location(100, 20)
--                  print(loc.x, loc.y)         -- 100  20
--
--              The member sturt can also be used as value constructor(and only
--          the member struct can be used as constructor), the argument order
--          is the same order as the declaration of it members.
--
--              The `x = Number` is the simplest way to declare a member to the
--          struct, but there are other details to be filled in, here is the
--          formal version:
--
--                  struct "Location" (function(_ENV)
--                      member "x" { Type = Number, Require = true }
--                      member "y" { Type = Number, Default = 0    }
--                  end)
--
--                  loc = Location{}            -- Error: Usage: Location(x, y) - x can't be nil
--                  loc = Location(100)
--                  print(loc.x, loc.y)         -- 100  0
--
--              The member is a keyword can only be used in the definition body
--          of a struct, it need a member name and a table contains several
--          settings(the field is case ignored) for the member:
--                  * Type      - The member's type, it could be any enum, struct,
--                      class or interface, also could be 3rd party types that
--                      follow rules(the type's prototype must provide a method
--                      named ValidateValue).
--                  * Require   - Whether the member can't be nil.
--                  * Default   - The default value of the member.
--
--              The member struct also support the validator and initializer :
--
--                  struct "MinMax" (function(_ENV)
--                      member "min" { Type = Number, Require = true }
--                      member "max" { Type = Number, Require = true }
--
--                      function MinMax(val)
--                          return val.min > val.max and "%s.min can't be greater than %s.max"
--                      end
--                  end)
--
--                  v = MinMax(100, 20) -- Error: Usage: MinMax(min, max) - min can't be greater than max
--
--              Since the member struct's value are tables, we also can define
--          struct methods that would be saved to those values:
--
--                  struct "Location" (function(_ENV)
--                      member "x" { Type = Number, Require = true }
--                      member "y" { Type = Number, Default = 0    }
--
--                      function GetRange(val)
--                          return math.sqrt(val.x^2 + val.y^2)
--                      end
--                  end)
--
--                  print(Location(3, 4):GetRange()) -- 5
--
--              We can also declare static methods that can only be used by the
--          struct itself(also for the custom struct):
--
--                  struct "Location" (function(_ENV)
--                      member "x" { Type = Number, Require = true }
--                      member "y" { Type = Number, Default = 0    }
--
--                      __Static__()
--                      function GetRange(val)
--                          return math.sqrt(val.x^2 + val.y^2)
--                      end
--                  end)
--
--                  print(Location.GetRange{x = 3, y = 4}) -- 5
--
--              The `__Static__` is an attribtue, it's used here to declare the
--          next defined method is a static one.
--
--              In the example, we declare the default value of the member in
--          the member's definition, but we also can provide the default value
--          in the custom struct like :
--
--                  struct "Number" (function(_ENV)
--                      __default = 0
--
--                      function Number(value)
--                          return type(value) ~= "number" and "%s must be number"
--                      end
--                  end)
--
--                  struct "Location" (function(_ENV)
--                      x = Number
--                      y = Number
--                  end)
--
--                  loc = Location()
--                  print(loc.x, loc.y)         -- 0    0
--
--              The member struct can also have base struct, it will inherit
--          members, non-static methods, validator and initializer, but it's
--          not recommended.
--
--iii. Array    The array structure represent tables that contains a list of
--          same type items. Here is an example to declare an array:
--
--                  struct "Locations" (function(_ENV)
--                      __array = Location
--                  end)
--
--                  v = Locations{ {x = true} } -- Usage: Locations(...) - [1].x must be number
--
--              The array structure also support methods, static methods, base
--          struct, validator and initializer.
--
-- To simplify the definition of the struct, table can be used instead of the
-- function as the definition body.
--
--                  -- Custom struct
--                  struct "Number" {
--                      __default = 0,  -- The default value
--                      -- the function with number index would be used as validator
--                      function (val) return type(val) ~= "number" end,
--                      -- Or you can clearly declare it
--                      __valid = function (val) return type(val) ~= "number" end,
--                  }
--
--                  struct "Boolean" {
--                      __init = function(val) return val and true or false end,
--                  }
--
--                  -- Member struct
--                  struct "Location" {
--                      -- Like use the member keyword, just with a name field
--                      { Name = "x", Type = Number, Require = true },
--                      { Name = "y", Type = Number, Require = true },
--
--                      -- Define methods
--                      GetRange = function(val) return math.sqrt(val.x^2 + val.y^2) end,
--                  }
--
--                  -- Array struct
--                  -- A valid type with number index, also can use the __array as the key
--                  struct "Locations" { Location }
--
-- If a data type's prototype can provide `ValidateValue(type, value)` method,
-- it'd be marked as a value type, the value type can be used in many places,
-- like the member's type, the array's element type, and class's property type.
--
-- The prototype has provided four value type's prototype: enum, struct, class
-- and interface.
--
--
-- iv. Let's return the first struct **Number**, the error message is generated
-- during runtime, and in PLoop there are many scenarios we only care whether
-- the value match the struct type, so we only need validation, not the error
-- message(the overload system use this technique to choose function).
--
-- The validator can receive 2nd parameter which indicated whether the system
-- only care if the value is valid:
--
--                  struct "Number" (function(_ENV)
--                      function Number(value, onlyvalid)
--                          if type(value) ~= "number" then return onlyvalid or "the %s must be number, got " .. type(value) end
--                      end
--                  end)
--
--                  print(struct.ValidateValue(Number, "test", true))   -- nil, true
--                  print(struct.ValidateValue(Number, "test", false))  -- nil, the %s must be number, got string
--
--
-- v. If your value could be two or more types, you can combine those types like :
--
--                  -- nil, the %s must be value of System.Number | System.String
--                  print(Struct.ValidateValue(Number + String, {}, false))
--
-- You can combine types like enums, structs, interfaces and classes.
--
--
-- vi. If you need the value to be a struct who is a sub type of another struct,
-- (the struct is a sub type of itself), you can create is like `- Number` :
--
--                  struct "Integer" { __base = Number, function(val) return math.floor(val) ~= val end }
--                  print(Struct.ValidateValue( - Number, Integer, false))  -- Integer
--
-- You also can use the `-` operation on interface or class.
--
-- @prototype   struct
-------------------------------------------------------------------------------
do
    -----------------------------------------------------------------------
    --                         attribute targets                         --
    -----------------------------------------------------------------------
    ATTRTAR_STRUCT              = attribute.RegisterTargetType("Struct")
    ATTRTAR_MEMBER              = attribute.RegisterTargetType("Member")
    ATTRTAR_METHOD              = attribute.RegisterTargetType("Method")

    -----------------------------------------------------------------------
    --                          public constants                         --
    -----------------------------------------------------------------------
    STRUCT_TYPE_MEMBER          = "MEMBER"
    STRUCT_TYPE_ARRAY           = "ARRAY"
    STRUCT_TYPE_CUSTOM          = "CUSTOM"

    -----------------------------------------------------------------------
    --                         private constants                         --
    -----------------------------------------------------------------------
    -- FEATURE MODIFIER
    local MOD_SEALED_STRUCT     = newflags(true)    -- SEALED
    local MOD_IMMUTABLE_STRUCT  = newflags()        -- IMMUTABLE

    -- FIELD INDEX
    local FLD_STRUCT_MOD        = -1                -- FIELD MODIFIER
    local FLD_STRUCT_TYPEMETHOD = -2                -- FIELD OBJECT METHODS
    local FLD_STRUCT_DEFAULT    = -3                -- FEILD DEFAULT
    local FLD_STRUCT_BASE       = -4                -- FIELD BASE STRUCT
    local FLD_STRUCT_VALID      = -5                -- FIELD VALIDATOR
    local FLD_STRUCT_CTOR       = -6                -- FIELD CONSTRUCTOR
    local FLD_STRUCT_NAME       = -7                -- FEILD STRUCT NAME
    local FLD_STRUCT_ERRMSG     = -8                -- FIELD ERROR MESSAGE
    local FLD_STRUCT_VALIDCACHE = -9                -- FIELD VALIDATOR CACHE

    local FLD_STRUCT_ARRAY      =  0                -- FIELD ARRAY ELEMENT
    local FLD_STRUCT_ARRVALID   =  2                -- FIELD ARRAY ELEMENT VALIDATOR
    local FLD_STRUCT_MEMBERSTART=  1                -- FIELD START INDEX OF MEMBER
    local FLD_STRUCT_VALIDSTART =  10000            -- FIELD START INDEX OF VALIDATOR
    local FLD_STRUCT_INITSTART  =  20000            -- FIELD START INDEX OF INITIALIZE

    -- MEMBER FIELD INDEX
    local FLD_MEMBER_OBJ        =  1                -- MEMBER FIELD OBJECT
    local FLD_MEMBER_NAME       =  2                -- MEMBER FIELD NAME
    local FLD_MEMBER_TYPE       =  3                -- MEMBER FIELD TYPE
    local FLD_MEMBER_VALID      =  4                -- MEMBER FIELD TYPE VALIDATOR
    local FLD_MEMBER_DEFAULT    =  5                -- MEMBER FIELD DEFAULT
    local FLD_MEMBER_DEFTFACTORY=  6                -- MEMBER FIELD AS DEFAULT FACTORY
    local FLD_MEMBER_REQUIRE    =  0                -- MEMBER FIELD REQUIRED

    -- TYPE FLAGS
    local FLG_CUSTOM_STRUCT     = newflags(true)    -- CUSTOM STRUCT FLAG
    local FLG_MEMBER_STRUCT     = newflags()        -- MEMBER STRUCT FLAG
    local FLG_ARRAY_STRUCT      = newflags()        -- ARRAY  STRUCT FLAG
    local FLG_STRUCT_SINGLE_VLD = newflags()        -- SINGLE VALID  FLAG
    local FLG_STRUCT_MULTI_VLD  = newflags()        -- MULTI  VALID  FLAG
    local FLG_STRUCT_SINGLE_INIT= newflags()        -- SINGLE INIT   FLAG
    local FLG_STRUCT_MULTI_INIT = newflags()        -- MULTI  INIT   FLAG
    local FLG_STRUCT_OBJ_METHOD = newflags()        -- OBJECT METHOD FLAG
    local FLG_STRUCT_VALIDCACHE = newflags()        -- VALID  CACHE  FLAG
    local FLG_STRUCT_MULTI_REQ  = newflags()        -- MULTI  FIELD  REQUIRE FLAG
    local FLG_STRUCT_FIRST_TYPE = newflags()        -- FIRST  MEMBER TYPE    FLAG
    local FLG_STRUCT_IMMUTABLE  = newflags()        -- IMMUTABLE     FLAG

    local STRUCT_KEYWORD_ARRAY  = "__array"
    local STRUCT_KEYWORD_BASE   = "__base"
    local STRUCT_KEYWORD_DFLT   = "__default"
    local STRUCT_KEYWORD_INIT   = "__init"
    local STRUCT_KEYWORD_VALD   = "__valid"

    -- UNSAFE MODE FIELDS
    local FLD_STRUCT_META       = "__PLOOP_STRUCT_META"
    local FLD_MEMBER_META       = "__PLOOP_STRUCT_MEMBER_META"

    -----------------------------------------------------------------------
    --                          private storage                          --
    -----------------------------------------------------------------------
    local _StructInfo           = PLOOP_PLATFORM_SETTINGS.UNSAFE_MODE
                                    and setmetatable({}, {__index = function(_, s) return type(s) == "table" and rawget(s, FLD_STRUCT_META) or nil end})
                                    or  newStorage(WEAK_KEY)
    local _MemberInfo           = PLOOP_PLATFORM_SETTINGS.UNSAFE_MODE
                                    and setmetatable({}, {__index = function(_, s) return type(s) == "table" and rawget(s, FLD_MEMBER_META) or nil end})
                                    or  newStorage(WEAK_KEY)
    local _DependenceMap        = newStorage(WEAK_KEY)

    -- TYPE BUILDING
    local _StructBuilderInfo    = newStorage(WEAK_KEY)
    local _StructBuilderInDefine= newStorage(WEAK_KEY)

    local _StructValidMap       = {}
    local _StructCtorMap        = {}

    -- Temp
    local _MemberAccessOwner
    local _MemberAccessName

    -----------------------------------------------------------------------
    --                          private helpers                          --
    -----------------------------------------------------------------------
    local getEnvValue           = environment.GetValue

    local getStructTargetInfo   = function (target)
        local info  = _StructBuilderInfo[target]
        if info then return info, true else return _StructInfo[target], false end
    end

    local setStructBuilderValue = function (self, key, value, stack, notenvset)
        local owner = environment.GetNamespace(self)
        if not (owner and _StructBuilderInDefine[self]) then return end

        local tkey  = type(key)
        local tval  = type(value)

        stack       = stack + 1

        if tkey == "string" and not tonumber(key) then
            if key == STRUCT_KEYWORD_DFLT then
                struct.SetDefault(owner, value, stack)
                return true
            elseif tval == "function" then
                if key == STRUCT_KEYWORD_INIT then
                    struct.SetInitializer(owner, value, stack)
                    return true
                elseif key == STRUCT_KEYWORD_VALD or key == namespace.GetNamespaceName(owner, true) then
                    struct.SetValidator(owner, value, stack)
                    return true
                else
                    struct.AddMethod(owner, key, value, stack)
                    return true
                end
            elseif getprototypemethod(value, "ValidateValue") then
                if key == STRUCT_KEYWORD_ARRAY then
                    struct.SetArrayElement(owner, value, stack)
                    return true
                elseif key == STRUCT_KEYWORD_BASE then
                    struct.SetBaseStruct(owner, value, stack)
                else
                    struct.AddMember(owner, key, { Type = value }, stack)
                end
                return true
            elseif tval == "table" and notenvset then
                struct.AddMember(owner, key, value, stack)
                return true
            end
        elseif tkey == "number" then
            if tval == "function" then
                struct.SetValidator(owner, value, stack)
                return true
            elseif getprototypemethod(value, "ValidateValue") then
                struct.SetArrayElement(owner, value, stack)
                return true
            elseif tval == "table" then
                struct.AddMember(owner, value, stack)
                return true
            else
                struct.SetDefault(owner, value, stack)
                return true
            end
        end
    end

    -- Check struct inner states
    local chkStructContent
        chkStructContent        = function (target, filter, cache)
        local info              = getStructTargetInfo(target)
        cache[target]           = true
        if not info then return end

        if info[FLD_STRUCT_ARRAY] then
            local array         = info[FLD_STRUCT_ARRAY]
            return not cache[array] and struct.Validate(array) and (filter(array) or chkStructContent(array, filter, cache))
        elseif info[FLD_STRUCT_MEMBERSTART] then
            for _, m in ipairs, info, FLD_STRUCT_MEMBERSTART - 1 do
                m               = m[FLD_MEMBER_TYPE]
                if not cache[m] and struct.Validate(m) and (filter(m) or chkStructContent(m, filter, cache)) then
                    return true
                end
            end
        end
    end

    local chkStructContents     = function (target, filter, incself)
        local cache             = _Cache()
        if incself and filter(target) then return true end
        local ret               = chkStructContent(target, filter, cache)
        _Cache(cache)
        return ret
    end

    local isNotSealedStruct     = function (target)
        local info, def         = getStructTargetInfo(target)
        return info and (def or not validateFlags(MOD_SEALED_STRUCT, info[FLD_STRUCT_MOD]))
    end

    local checkStructDependence = function (target, chkType)
        if chkType and target ~= chkType then
            if chkStructContents(chkType, isNotSealedStruct, true) then
                _DependenceMap[chkType]         = _DependenceMap[chkType] or newStorage(WEAK_KEY)
                _DependenceMap[chkType][target] = true
            elseif chkType and _DependenceMap[chkType] then
                _DependenceMap[chkType][target] = nil
                if not next(_DependenceMap[chkType]) then _DependenceMap[chkType] = nil end
            end
        end
    end

    local updateStructDependence= function (target, info)
        info = info or getStructTargetInfo(target)

        if info[FLD_STRUCT_ARRAY] then
            checkStructDependence(target, info[FLD_STRUCT_ARRAY])
        elseif info[FLD_STRUCT_MEMBERSTART] then
            for _, m in ipairs, info, FLD_STRUCT_MEMBERSTART - 1 do
                checkStructDependence(target, m[FLD_MEMBER_TYPE])
            end
        end
    end

    -- Immutable
    local checkStructImmutable  = function (info)
        if info[FLD_STRUCT_INITSTART]  then return false end
        if info[FLD_STRUCT_TYPEMETHOD] then for k, v in pairs, info[FLD_STRUCT_TYPEMETHOD] do if v then return false end end end

        local arrtype = info[FLD_STRUCT_ARRAY]
        if arrtype then
            return getobjectvalue(arrtype, "IsImmutable") or false
        elseif info[FLD_STRUCT_MEMBERSTART] then
            for _, m in ipairs, info, FLD_STRUCT_MEMBERSTART - 1 do
                if not getobjectvalue(m[FLD_MEMBER_TYPE], "IsImmutable") then return false end
            end
        end
        return true
    end

    local updateStructImmutable = function (target, info)
        info = info or getStructTargetInfo(target)
        if checkStructImmutable(info) then
            info[FLD_STRUCT_MOD]= turnOnFlags(MOD_IMMUTABLE_STRUCT, info[FLD_STRUCT_MOD])
        else
            info[FLD_STRUCT_MOD]= turnOffFlags(MOD_IMMUTABLE_STRUCT, info[FLD_STRUCT_MOD])
        end
    end

    -- Cache required
    local checkRepeatStructType = function (target, info)
        if info then
            local filter        = function(chkType) return chkType == target end

            if info[FLD_STRUCT_ARRAY] then
                local array     = info[FLD_STRUCT_ARRAY]
                return array == target or (struct.Validate(array) and chkStructContents(array, filter))
            elseif info[FLD_STRUCT_MEMBERSTART] then
                for _, m in ipairs, info, FLD_STRUCT_MEMBERSTART - 1 do
                    m           = m[FLD_MEMBER_TYPE]
                    if m == target or (struct.Validate(m) and chkStructContents(m, filter)) then
                        return true
                    end
                end
            end
        end

        return false
    end

    -- Validator
    local genStructValidator    = function (info)
        local token = 0
        local upval = _Cache()

        if info[FLD_STRUCT_VALIDCACHE] then
            token   = turnOnFlags(FLG_STRUCT_VALIDCACHE, token)
        end

        if info[FLD_STRUCT_MEMBERSTART] then
            token   = turnOnFlags(FLG_MEMBER_STRUCT, token)
            local i = FLD_STRUCT_MEMBERSTART
            while info[i + 1] do i = i + 1 end
            tinsert(upval, i)
        elseif info[FLD_STRUCT_ARRAY] then
            token   = turnOnFlags(FLG_ARRAY_STRUCT, token)
        else
            token   = turnOnFlags(FLG_CUSTOM_STRUCT, token)
        end

        if info[FLD_STRUCT_VALIDSTART] then
            if info[FLD_STRUCT_VALIDSTART + 1] then
                local i = FLD_STRUCT_VALIDSTART + 2
                while info[i] do i = i + 1 end
                token = turnOnFlags(FLG_STRUCT_MULTI_VLD, token)
                tinsert(upval, i - 1)
            else
                token = turnOnFlags(FLG_STRUCT_SINGLE_VLD, token)
                tinsert(upval, info[FLD_STRUCT_VALIDSTART])
            end
        end

        if info[FLD_STRUCT_INITSTART] then
            if info[FLD_STRUCT_INITSTART + 1] then
                local i = FLD_STRUCT_INITSTART + 2
                while info[i] do i = i + 1 end
                token = turnOnFlags(FLG_STRUCT_MULTI_INIT, token)
                tinsert(upval, i - 1)
            else
                token = turnOnFlags(FLG_STRUCT_SINGLE_INIT, token)
                tinsert(upval, info[FLD_STRUCT_INITSTART])
            end
        end

        if info[FLD_STRUCT_TYPEMETHOD] then
            for k, v in pairs, info[FLD_STRUCT_TYPEMETHOD] do
                if v then
                    token   = turnOnFlags(FLG_STRUCT_OBJ_METHOD, token)
                    break
                end
            end
        end

        -- Build the validator generator
        if not _StructValidMap[token] then
            local head      = _Cache()
            local body      = _Cache()
            local apis      = _Cache()

            tinsert(body, "")                       -- remain for shareable variables
            tinsert(body, "return function(%s)")    -- remain for special variables
            tinsert(body, [[return function(info, value, onlyValid, cache)]])

            if validateFlags(FLG_MEMBER_STRUCT, token) or validateFlags(FLG_ARRAY_STRUCT, token) then
                uinsert(apis, "strformat")
                uinsert(apis, "type")
                uinsert(apis, "strgsub")
                uinsert(apis, "tostring")
                uinsert(apis, "getmetatable")

                tinsert(body, [[
                    if type(value)         ~= "table" then return nil, onlyValid or "the %s must be a table" end
                    if getmetatable(value) ~= nil     then return nil, onlyValid or "the %s must be a table without meta-table" end
                ]])

                if validateFlags(FLG_STRUCT_VALIDCACHE, token) then
                    uinsert(apis, "_Cache")
                    tinsert(body, [[
                        -- Cache to block recursive validation
                        local vcache = cache[info]
                        if not vcache then
                            vcache = _Cache()
                            cache[info] = vcache
                        elseif vcache[value] then
                            return value
                        end
                        vcache[value]= true
                    ]])
                end
            end

            if validateFlags(FLG_MEMBER_STRUCT, token) then
                uinsert(apis, "clone")

                tinsert(head, "count")
                tinsert(body, [[
                    if onlyValid then
                        for i = ]] .. FLD_STRUCT_MEMBERSTART .. [[, count do
                            local mem  = info[i]
                            local name = mem[]] .. FLD_MEMBER_NAME .. [[]
                            local vtype= mem[]] .. FLD_MEMBER_TYPE ..[[]
                            local val  = value[name]
                            local msg

                            if val == nil then
                                if mem[]] .. FLD_MEMBER_REQUIRE .. [[] then
                                    return nil, true
                                end
                            elseif vtype then
                                val, msg = mem[]] .. FLD_MEMBER_VALID .. [[](vtype, val, true, cache)
                                if msg then return nil, true end
                            end
                        end
                    else
                        for i = ]] .. FLD_STRUCT_MEMBERSTART .. [[, count do
                            local mem  = info[i]
                            local name = mem[]] .. FLD_MEMBER_NAME .. [[]
                            local vtype= mem[]] .. FLD_MEMBER_TYPE ..[[]
                            local val  = value[name]
                            local msg

                            if val == nil then
                                if mem[]] .. FLD_MEMBER_REQUIRE .. [[] then
                                    return nil, strformat("the %s.%s can't be nil", "%s", name)
                                end

                                if mem[]] .. FLD_MEMBER_DEFTFACTORY .. [[] then
                                    val= mem[]] .. FLD_MEMBER_DEFAULT .. [[](value)
                                else
                                    val= clone(mem[]] .. FLD_MEMBER_DEFAULT .. [[], true)
                                end
                            elseif vtype then
                                val, msg = mem[]] .. FLD_MEMBER_VALID .. [[](vtype, val, false, cache)
                                if msg then return nil, type(msg) == "string" and strgsub(msg, "%%s", "%%s" .. "." .. name) or strformat("the %s.%s must be [%s]", "%s", name, tostring(vtype)) end
                            end

                            value[name] = val
                        end
                    end
                ]])
            elseif validateFlags(FLG_ARRAY_STRUCT, token) then
                uinsert(apis, "ipairs")

                tinsert(body, [[
                    local array = info[]] .. FLD_STRUCT_ARRAY .. [[]
                    local avalid= info[]] .. FLD_STRUCT_ARRVALID .. [[]
                    if onlyValid then
                        for i, v in ipairs, value, 0 do
                            local ret, msg  = avalid(array, v, true, cache)
                            if msg then return nil, true end
                        end
                    else
                        for i, v in ipairs, value, 0 do
                            local ret, msg  = avalid(array, v, false, cache)
                            if msg then return nil, type(msg) == "string" and strgsub(msg, "%%s", "%%s[" .. i .. "]") or strformat("the %s[%s] must be [%s]", "%s", i, tostring(array)) end
                            value[i] = ret
                        end
                    end
                ]])
            end

            if validateFlags(FLG_STRUCT_SINGLE_VLD, token) or validateFlags(FLG_STRUCT_MULTI_VLD, token) then
                uinsert(apis, "type")
                uinsert(apis, "strformat")

                if validateFlags(FLG_STRUCT_SINGLE_VLD, token) then
                    tinsert(head, "svalid")
                    tinsert(body, [[
                        local msg = svalid(value, onlyValid)
                        if msg then return nil, onlyValid or type(msg) == "string" and msg or strformat("the %s must be [%s]", "%s", info[]] .. FLD_STRUCT_NAME .. [[]) end
                    ]])
                elseif validateFlags(FLG_STRUCT_MULTI_VLD, token) then
                    tinsert(head, "mvalid")
                    tinsert(body, [[
                        for i = ]] .. FLD_STRUCT_VALIDSTART .. [[, mvalid do
                            local msg = info[i](value, onlyValid)
                            if msg then return nil, onlyValid or type(msg) == "string" and msg or strformat("the %s must be [%s]", "%s", info[]] .. FLD_STRUCT_NAME .. [[]) end
                        end
                    ]])
                end
            end

            if validateFlags(FLG_STRUCT_SINGLE_INIT, token) or validateFlags(FLG_STRUCT_MULTI_INIT, token) or validateFlags(FLG_STRUCT_OBJ_METHOD, token) then
                tinsert(body, [[if onlyValid then return value end]])
            end

            if validateFlags(FLG_STRUCT_SINGLE_INIT, token) or validateFlags(FLG_STRUCT_MULTI_INIT, token) then
                if validateFlags(FLG_STRUCT_SINGLE_INIT, token) then
                    tinsert(head, "sinit")
                    tinsert(body, [[
                        local ret = sinit(value)
                    ]])

                    if validateFlags(FLG_CUSTOM_STRUCT, token) then
                        tinsert(body, [[if ret ~= nil then value = ret end]])
                    end
                else
                    tinsert(head, "minit")
                    tinsert(body, [[
                        for i = ]] .. FLD_STRUCT_INITSTART .. [[, minit do
                            local ret = info[i](value)
                        ]])
                    if validateFlags(FLG_CUSTOM_STRUCT, token) then
                        tinsert(body, [[if ret ~= nil then value = ret end]])
                    end
                    tinsert(body, [[end]])
                end
            end

            if validateFlags(FLG_STRUCT_OBJ_METHOD, token) then
                if validateFlags(FLG_CUSTOM_STRUCT, token) then
                    uinsert(apis, "type")
                    tinsert(body, [[if type(value) == "table" then]])
                end
                uinsert(apis, "pairs")
                tinsert(body, [[
                    for k, v in pairs, info[]] .. FLD_STRUCT_TYPEMETHOD .. [[] do
                        if v and value[k] == nil then value[k] = v end
                    end
                ]])

                if validateFlags(FLG_CUSTOM_STRUCT, token) then
                    tinsert(body, [[end]])
                end
            end

            tinsert(body, [[
                    return value
                end
            ]])

            tinsert(body, [[end]])

            if #apis > 0 then
                local declare   = tblconcat(apis, ", ")
                body[1]         = strformat("local %s = %s", declare, declare)
            end

            body[2]             = strformat(body[2], #head > 0 and tblconcat(head, ", ") or "")

            _StructValidMap[token]  = loadSnippet(tblconcat(body, "\n"), "Struct_Validate_" .. token)()

            if #head == 0 then
                _StructValidMap[token] = _StructValidMap[token]()
            end

            _Cache(head)
            _Cache(body)
            _Cache(apis)
        end

        if #upval > 0 then
            info[FLD_STRUCT_VALID] = _StructValidMap[token](unpack(upval))
        else
            info[FLD_STRUCT_VALID] = _StructValidMap[token]
        end

        _Cache(upval)
    end

    -- Ctor
    local genStructConstructor  = function (info)
        local token = 0
        local upval = _Cache()

        if info[FLD_STRUCT_VALIDCACHE] then
            token   = turnOnFlags(FLG_STRUCT_VALIDCACHE, token)
        end

        if info[FLD_STRUCT_MEMBERSTART] then
            token   = turnOnFlags(FLG_MEMBER_STRUCT, token)
            local i = FLD_STRUCT_MEMBERSTART + 1
            local r = false
            while info[i] do
                if not r and info[i][FLD_MEMBER_REQUIRE] then r = true end
                i = i + 1
            end
            tinsert(upval, i - 1)
            if r then
                token = turnOnFlags(FLG_STRUCT_MULTI_REQ, token)
            else
                local ftype = info[FLD_STRUCT_MEMBERSTART][FLD_MEMBER_TYPE]
                if ftype then
                    token = turnOnFlags(FLG_STRUCT_FIRST_TYPE, token)
                    tinsert(upval, ftype)
                    tinsert(upval, info[FLD_STRUCT_MEMBERSTART][FLD_MEMBER_VALID])
                    tinsert(upval, getobjectvalue(ftype, "IsImmutable") or false)
                end
            end
        elseif info[FLD_STRUCT_ARRAY] then
            token   = turnOnFlags(FLG_ARRAY_STRUCT, token)
        else
            token   = turnOnFlags(FLG_CUSTOM_STRUCT, token)
        end

        if validateFlags(MOD_IMMUTABLE_STRUCT, info[FLD_STRUCT_MOD]) then
            token           = turnOnFlags(FLG_STRUCT_IMMUTABLE, token)
        end

        -- Build the validator generator
        if not _StructCtorMap[token] then
            local head      = _Cache()
            local body      = _Cache()
            local apis      = _Cache()

            tinsert(body, "")                       -- remain for shareable variables
            tinsert(body, "return function(%s)")    -- remain for special variables

            uinsert(apis, "error")
            uinsert(apis, "strgsub")

            if validateFlags(FLG_MEMBER_STRUCT, token) then
                uinsert(apis, "select")
                uinsert(apis, "type")
                uinsert(apis, "getmetatable")

                tinsert(body, [[
                    return function(info, first, ...)
                        local ivalid = info[]].. FLD_STRUCT_VALID .. [[]
                        local ret, msg
                        if select("#", ...) == 0 and type(first) == "table" and getmetatable(first) == nil then
                ]])

                tinsert(head, "count")
                if not validateFlags(FLG_STRUCT_MULTI_REQ, token) then
                    -- So, it may be the first member
                    if validateFlags(FLG_STRUCT_FIRST_TYPE, token) then
                        tinsert(head, "ftype")
                        tinsert(head, "fvalid")
                        tinsert(head, "fimtbl")
                        tinsert(body, [[
                            local _, fmatch = fvalid(ftype, first, true) fmatch = not fmatch
                        ]])
                    else
                        tinsert(body, [[local fmatch, fimtbl = true, true]])
                    end
                else
                    tinsert(body, [[local fmatch, fimtbl = false, false]])
                end

                if validateFlags(FLG_STRUCT_VALIDCACHE, token) then
                    tinsert(body, [[
                        local cache = _Cache()
                        ret, msg    = ivalid(info, first, fmatch and not fimtbl, cache)
                        for k, v in pairs, cache do cache[k] = nil _Cache(v) end _Cache(cache)
                    ]])
                else
                    tinsert(body, [[ret, msg = ivalid(info, first, fmatch and not fimtbl)]])
                end

                tinsert(body, [[if not msg then]])

                if not validateFlags(FLG_STRUCT_IMMUTABLE, token) then
                    tinsert(body, [[if fmatch and not fimtbl then]])

                    if validateFlags(FLG_STRUCT_VALIDCACHE, token) then
                        tinsert(body, [[
                            local cache = _Cache()
                            ret, msg = ivalid(info, first, false, cache)
                            for k, v in pairs, cache do cache[k] = nil _Cache(v) end _Cache(cache)
                        ]])
                    else
                        tinsert(body, [[ret, msg = ivalid(info, first, false)]])
                    end

                    tinsert(body, [[end]])
                end

                tinsert(body, [[
                            return ret
                        elseif not fmatch then
                            error(info[]] .. FLD_STRUCT_ERRMSG .. [[] .. (type(msg) == "string" and strgsub(msg, "%%s%.?", "") or "the value is not valid."), 3)
                        end
                    end
                ]])
            else
                tinsert(body, [[
                    return function(info, ret)
                        local ivalid = info[]].. FLD_STRUCT_VALID .. [[]
                        local msg
                ]])
            end

            if validateFlags(FLG_MEMBER_STRUCT, token) then
                tinsert(body, [[
                    ret = {}
                    local j = 1
                    ret[ info[]] .. FLD_STRUCT_MEMBERSTART .. [[][]] .. FLD_MEMBER_NAME .. [[] ] = first
                    for i = ]] .. (FLD_STRUCT_MEMBERSTART + 1) .. [[, count do
                        ret[ info[i][]] .. FLD_MEMBER_NAME .. [[] ] = (select(j, ...))
                        j = j + 1
                    end
                ]])
            end

            if validateFlags(FLG_STRUCT_VALIDCACHE, token) then
                uinsert(apis, "_Cache")
                uinsert(apis, "pairs")
                tinsert(body, [[
                    local cache = _Cache()
                    ret, msg = ivalid(info, ret, false, cache)
                    for k, v in pairs, cache do cache[k] = nil _Cache(v) end _Cache(cache)
                ]])
            else
                tinsert(body, [[
                    ret, msg = ivalid(info, ret, false)
                ]])
            end

            tinsert(body, [[if not msg then return ret end]])

            if validateFlags(FLG_MEMBER_STRUCT, token) or validateFlags(FLG_ARRAY_STRUCT, token) then
                uinsert(apis, "type")
                tinsert(body, [[
                    error(info[]] .. FLD_STRUCT_ERRMSG .. [[] .. (type(msg) == "string" and strgsub(msg, "%%s%.?", "") or "the value is not valid."), 3)
                ]])
            else
                tinsert(body, [[
                    error(strgsub(msg, "%%s", "value"), 3)
                ]])
            end

            tinsert(body, [[end]])

            tinsert(body, [[end]])

            if #apis > 0 then
                local declare   = tblconcat(apis, ", ")
                body[1]         = strformat("local %s = %s", declare, declare)
            end

            body[2]             = strformat(body[2], #head > 0 and tblconcat(head, ", ") or "")

            _StructCtorMap[token] = loadSnippet(tblconcat(body, "\n"), "Struct_Ctor_" .. token)()

            if #head == 0 then
                _StructCtorMap[token] = _StructCtorMap[token]()
            end

            _Cache(head)
            _Cache(body)
            _Cache(apis)
        end

        if #upval > 0 then
            info[FLD_STRUCT_CTOR] = _StructCtorMap[token](unpack(upval))
        else
            info[FLD_STRUCT_CTOR] = _StructCtorMap[token]
        end

        _Cache(upval)
    end

    -- Refresh Depends
    local updateStructDepends
        updateStructDepends     = function (target, cache)
        local map = _DependenceMap[target]

        if map then
            _DependenceMap[target] = nil

            for t in pairs, map do
                if not cache[t] then
                    cache[t] = true

                    local info, def = getStructTargetInfo(t)
                    if not def then
                        info[FLD_STRUCT_VALIDCACHE] = checkRepeatStructType(t, info)

                        updateStructDependence(t, info)
                        updateStructImmutable (t, info)

                        genStructValidator  (info)
                        genStructConstructor(info)

                        updateStructDepends (t, cache)
                    end
                end
            end

            _Cache(map)
        end
    end

    -- Save Meta
    local saveStructMeta        = PLOOP_PLATFORM_SETTINGS.UNSAFE_MODE
                                    and function (s, meta) rawset(s, FLD_STRUCT_META, meta) end
                                    or  function (s, meta) _StructInfo = saveStorage(_StructInfo, s, meta) end

    local saveMemberMeta        = PLOOP_PLATFORM_SETTINGS.UNSAFE_MODE
                                    and function (m, meta) rawset(m, FLD_MEMBER_META, meta) end
                                    or  function (m, meta) _MemberInfo = saveStorage(_MemberInfo, m, meta) end

    -----------------------------------------------------------------------
    --                             prototype                             --
    -----------------------------------------------------------------------
    struct                      = prototype {
        __tostring              = "struct",
        __index                 = {
            --- Add a member to the structure
            -- @static
            -- @method  AddMember
            -- @owner   struct
            -- @format  (structure[, name], definition[, stack])
            -- @param   structure                   the structure
            -- @param   name                        the member's name
            -- @param   definition                  the member's definition like { type = [Value type], default = [value], require = [boolean], name = [string] }
            -- @param   stack                       the stack level
            ["AddMember"]       = function(target, name, definition, stack)
                local info, def = getStructTargetInfo(target)

                if type(name) == "table" then
                    definition, stack, name = name, definition, nil
                    for k, v in pairs, definition do
                        if type(k) == "string" and strlower(k) == "name" and type(v) == "string" and not tonumber(v) then
                            name, definition[k] = v, nil
                            break
                        end
                    end
                end
                stack           = parsestack(stack) + 1

                if info then
                    if not def then error(strformat("Usage: struct.AddMember(structure[, name], definition[, stack]) - The %s's definition is finished", tostring(target)), stack) end
                    if type(name) ~= "string" then error("Usage: struct.AddMember(structure[, name], definition[, stack]) - The name must be a string", stack) end
                    name = strtrim(name)
                    if name == "" then error("Usage: struct.AddMember(structure[, name], definition[, stack]) - The name can't be empty", stack) end
                    if type(definition) ~= "table" then error("Usage: struct.AddMember(structure[, name], definition[, stack]) - The definition is missing", stack) end
                    if info[FLD_STRUCT_ARRAY] then error("Usage: struct.AddMember(structure[, name], definition[, stack]) - The structure is an array structure, can't add member", stack) end

                    local idx = FLD_STRUCT_MEMBERSTART
                    while info[idx] do
                        if info[idx][FLD_MEMBER_NAME] == name then
                            error(strformat("Usage: struct.AddMember(structure[, name], definition[, stack]) - There is an existed member with the name : %q", name), stack)
                        end
                        idx     = idx + 1
                    end

                    local mobj  = prototype.NewProxy(member)
                    local minfo = _Cache()
                    saveMemberMeta(mobj, minfo)
                    minfo[FLD_MEMBER_OBJ]   = mobj
                    minfo[FLD_MEMBER_NAME]  = name

                    -- Save attributes
                    attribute.SaveAttributes(mobj, ATTRTAR_MEMBER, stack)

                    -- Inherit attributes
                    if info[FLD_STRUCT_BASE] then
                        local smem  = struct.GetMember(info[FLD_STRUCT_BASE], name)
                        if smem  then attribute.InheritAttributes(mobj, ATTRTAR_MEMBER, smem) end
                    end

                    -- Init the definition with attributes
                    definition = attribute.InitDefinition(mobj, ATTRTAR_MEMBER, definition, target, name, stack)

                    -- Parse the definition
                    for k, v in pairs, definition do
                        if type(k) == "string" then
                            k = strlower(k)

                            if k == "type" then
                                local tpValid = getprototypemethod(v, "ValidateValue")

                                if tpValid then
                                    minfo[FLD_MEMBER_TYPE]  = v
                                    minfo[FLD_MEMBER_VALID] = tpValid
                                else
                                    error("Usage: struct.AddMember(structure[, name], definition[, stack]) - The member's type is not valid", stack)
                                end
                            elseif k == "require" and v then
                                minfo[FLD_MEMBER_REQUIRE]   = true
                            elseif k == "default" then
                                minfo[FLD_MEMBER_DEFAULT]   = v
                            end
                        end
                    end

                    if minfo[FLD_MEMBER_REQUIRE] then
                        minfo[FLD_MEMBER_DEFAULT] = nil
                    elseif minfo[FLD_MEMBER_TYPE] then
                        if minfo[FLD_MEMBER_DEFAULT] ~= nil then
                            local ret, msg  = minfo[FLD_MEMBER_VALID](minfo[FLD_MEMBER_TYPE], minfo[FLD_MEMBER_DEFAULT])
                            if not msg then
                                minfo[FLD_MEMBER_DEFAULT]       = ret
                            elseif type(minfo[FLD_MEMBER_DEFAULT]) == "function" then
                                minfo[FLD_MEMBER_DEFTFACTORY]   = true
                            else
                                error("Usage: struct.AddMember(structure[, name], definition[, stack]) - The default value is not valid", stack)
                            end
                        end
                        if minfo[FLD_MEMBER_DEFAULT] == nil then
                            minfo[FLD_MEMBER_DEFAULT] = getobjectvalue(minfo[FLD_MEMBER_TYPE], "GetDefault")
                        end
                    end

                    info[idx] = minfo
                    attribute.ApplyAttributes (mobj, ATTRTAR_MEMBER, target, name, stack)
                    attribute.AttachAttributes(mobj, ATTRTAR_MEMBER, target, name, stack)
                else
                    error("Usage: struct.AddMember(structure[, name], definition[, stack]) - The structure is not valid", stack)
                end
            end;

            --- Add an object method to the structure
            -- @static
            -- @method  AddMethod
            -- @owner   struct
            -- @format  (structure, name, func[, stack])
            -- @param   structure                   the structure
            -- @param   name                        the method'a name
            -- @param   func                        the method's definition
            -- @param   stack                       the stack level
            ["AddMethod"]       = function(target, name, func, stack)
                local info, def = getStructTargetInfo(target)
                stack = parsestack(stack) + 1

                if info then
                    if not def then error(strformat("Usage: struct.AddMethod(structure, name, func[, stack]) - The %s's definition is finished", tostring(target)), stack) end
                    if type(name) ~= "string" then error("Usage: struct.AddMethod(structure, name, func[, stack]) - The name must be a string", stack) end
                    name = strtrim(name)
                    if name == "" then error("Usage: Usage: struct.AddMethod(structure, name, func[, stack]) - The name can't be empty", stack) end
                    if type(func) ~= "function" then error("Usage: struct.AddMethod(structure, name, func[, stack]) - The func must be a function", stack) end

                    attribute.SaveAttributes(func, ATTRTAR_METHOD, stack)

                    if info[FLD_STRUCT_BASE] and not info[name] then
                        local sfunc = struct.GetMethod(info[FLD_STRUCT_BASE], name)
                        if sfunc then attribute.InheritAttributes(func, ATTRTAR_METHOD, sfunc) end
                    end

                    local ret = attribute.InitDefinition(func, ATTRTAR_METHOD, func, target, name, stack)
                    if ret ~= func then attribute.ToggleTarget(func, ret) func = ret end

                    if info[FLD_STRUCT_TYPEMETHOD] and info[FLD_STRUCT_TYPEMETHOD][name] == false then
                        info[name]  = func
                    else
                        info[FLD_STRUCT_TYPEMETHOD]         = info[FLD_STRUCT_TYPEMETHOD] or {}
                        info[FLD_STRUCT_TYPEMETHOD][name]   = func
                    end

                    attribute.ApplyAttributes (func, ATTRTAR_METHOD, target, name, stack)
                    attribute.AttachAttributes(func, ATTRTAR_METHOD, target, name, stack)
                else
                    error("Usage: struct.AddMethod(structure, name, func[, stack]) - The structure is not valid", stack)
                end
            end;

            --- Begin the structure's definition
            -- @static
            -- @method  BeginDefinition
            -- @owner   struct
            -- @format  (structure[, stack])
            -- @param   structure                   the structure
            -- @param   stack                       the stack level
            ["BeginDefinition"] = function(target, stack)
                stack = parsestack(stack) + 1

                target          = struct.Validate(target)
                if not target then error("Usage: struct.BeginDefinition(structure[, stack]) - The structure not existed", stack) end

                local info      = _StructInfo[target]

                if info and validateFlags(MOD_SEALED_STRUCT, info[FLD_STRUCT_MOD]) then error(strformat("Usage: struct.BeginDefinition(structure[, stack]) - The %s is sealed, can't be re-defined", tostring(target)), stack) end
                if _StructBuilderInfo[target] then error(strformat("Usage: struct.BeginDefinition(structure[, stack]) - The %s's definition has already begun", tostring(target)), stack) end

                _StructBuilderInfo      = saveStorage(_StructBuilderInfo, target, {
                    [FLD_STRUCT_MOD ]   = 0,
                    [FLD_STRUCT_NAME]   = tostring(target),
                })

                attribute.SaveAttributes(target, ATTRTAR_STRUCT, stack)
            end;

            --- End the structure's definition
            -- @static
            -- @method  EndDefinition
            -- @owner   struct
            -- @format  (structure[, stack])
            -- @param   structure                   the structure
            -- @param   stack                       the stack level
            ["EndDefinition"]   = function(target, stack)
                local ninfo     = _StructBuilderInfo[target]
                if not ninfo then return end

                stack = parsestack(stack) + 1

                attribute.ApplyAttributes(target, ATTRTAR_STRUCT, nil, nil, stack)

                _StructBuilderInfo  = saveStorage(_StructBuilderInfo, target, nil)

                -- Install base struct's features
                if ninfo[FLD_STRUCT_BASE] then
                    -- Check conflict, some should be handled by the author
                    local binfo = _StructInfo[ninfo[FLD_STRUCT_BASE]]

                    if ninfo[FLD_STRUCT_ARRAY] then             -- Array
                        if not binfo[FLD_STRUCT_ARRAY] then
                            error(strformat("Usage: struct.EndDefinition(structure[, stack]) - The %s's base struct isn't an array structure", tostring(target)), stack)
                        end
                    elseif ninfo[FLD_STRUCT_MEMBERSTART] then   -- Member
                        if binfo[FLD_STRUCT_ARRAY] then
                            error(strformat("Usage: struct.EndDefinition(structure[, stack]) - The %s's base struct can't be an array structure", tostring(target)), stack)
                        elseif binfo[FLD_STRUCT_MEMBERSTART] then
                            -- Try to keep the base struct's member order
                            local cache     = _Cache()
                            local idx       = FLD_STRUCT_MEMBERSTART
                            while ninfo[idx] do
                                tinsert(cache, ninfo[idx])
                                idx         = idx + 1
                            end

                            local memCnt    = #cache

                            idx             = FLD_STRUCT_MEMBERSTART
                            while binfo[idx] do
                                local name  = binfo[idx][FLD_MEMBER_NAME]
                                ninfo[idx]  = binfo[idx]

                                for k, v in pairs, cache do
                                    if name == v[FLD_MEMBER_NAME] then
                                        ninfo[idx]  = v
                                        cache[k]    = nil
                                        break
                                    end
                                end

                                idx         = idx + 1
                            end

                            for i = 1, memCnt do
                                if cache[i] then
                                    ninfo[idx]      = cache[i]
                                    idx             = idx + 1
                                end
                            end

                            _Cache(cache)
                        end
                    else                                        -- Custom
                        if binfo[FLD_STRUCT_ARRAY] then
                            ninfo[FLD_STRUCT_ARRAY] = binfo[FLD_STRUCT_ARRAY]
                            ninfo[FLD_STRUCT_ARRVALID]= binfo[FLD_STRUCT_ARRVALID]
                        elseif binfo[FLD_STRUCT_MEMBERSTART] then
                            -- Share members
                            local idx = FLD_STRUCT_MEMBERSTART
                            while binfo[idx] do
                                ninfo[idx]  = binfo[idx]
                                idx         = idx + 1
                            end
                        end
                    end

                    -- Clone the validator and Initializer
                    local nvalid    = ninfo[FLD_STRUCT_VALIDSTART]
                    local ninit     = ninfo[FLD_STRUCT_INITSTART]

                    local idx       = FLD_STRUCT_VALIDSTART
                    while binfo[idx] do
                        ninfo[idx]  = binfo[idx]
                        idx         = idx + 1
                    end
                    ninfo[idx]      = nvalid

                    idx             = FLD_STRUCT_INITSTART
                    while binfo[idx] do
                        ninfo[idx]  = binfo[idx]
                        idx         = idx + 1
                    end
                    ninfo[idx]      = ninit

                    -- Clone the methods
                    if binfo[FLD_STRUCT_TYPEMETHOD] then
                        nobjmtd     = ninfo[FLD_STRUCT_TYPEMETHOD] or _Cache()

                        for k, v in pairs, binfo[FLD_STRUCT_TYPEMETHOD] do
                            if v and nobjmtd[k] == nil then
                                nobjmtd[k]  = v
                            end
                        end

                        if next(nobjmtd) then
                            ninfo[FLD_STRUCT_TYPEMETHOD] = nobjmtd
                        else
                            ninfo[FLD_STRUCT_TYPEMETHOD] = nil
                            _Cache(nobjmtd)
                        end
                    end
                end

                -- Generate error message
                if ninfo[FLD_STRUCT_MEMBERSTART] then
                    local args      = _Cache()
                    local idx       = FLD_STRUCT_MEMBERSTART
                    while ninfo[idx] do
                        tinsert(args, ninfo[idx][FLD_MEMBER_NAME])
                        idx         = idx + 1
                    end
                    ninfo[FLD_STRUCT_ERRMSG]    = strformat("Usage: %s(%s) - ", tostring(target), tblconcat(args, ", "))
                    _Cache(args)
                elseif ninfo[FLD_STRUCT_ARRAY] then
                    ninfo[FLD_STRUCT_ERRMSG]    = strformat("Usage: %s(...) - ", tostring(target))
                else
                    ninfo[FLD_STRUCT_ERRMSG]    = strformat("[%s]", tostring(target))
                end

                ninfo[FLD_STRUCT_VALIDCACHE]    = checkRepeatStructType(target, ninfo)

                updateStructDependence(target, ninfo)
                updateStructImmutable(target, ninfo)

                genStructValidator(ninfo)
                genStructConstructor(ninfo)

                -- Save as new structure's info
                saveStructMeta(target, ninfo)

                -- Check the default value is it's custom struct
                if ninfo[FLD_STRUCT_DEFAULT] ~= nil then
                    local deft      = ninfo[FLD_STRUCT_DEFAULT]
                    ninfo[FLD_STRUCT_DEFAULT]  = nil

                    if not ninfo[FLD_STRUCT_ARRAY] and not ninfo[FLD_STRUCT_MEMBERSTART] then
                        local ret, msg = struct.ValidateValue(target, deft)
                        if not msg then ninfo[FLD_STRUCT_DEFAULT] = ret end
                    end
                end

                attribute.AttachAttributes(target, ATTRTAR_STRUCT, nil, nil, stack)

                -- Refresh structs depended on this
                if _DependenceMap[target] then
                    local cache = _Cache()
                    cache[target] = true
                    updateStructDepends(target, cache)
                    _Cache(cache)
                end

                return target
            end;

            --- Get the array structure's element type
            -- @static
            -- @method  GetArrayElement
            -- @owner   struct
            -- @param   structure                   the structure
            -- @return  type                        the array element's type
            ["GetArrayElement"] = function(target)
                local info      = getStructTargetInfo(target)
                return info and info[FLD_STRUCT_ARRAY]
            end;

            --- Get the structure's base struct type
            -- @static
            -- @method  GetBaseStruct
            -- @owner   struct
            -- @param   structure                   the structure
            -- @return  type                        the base struct
            ["GetBaseStruct"]   = function(target)
                local info      = getStructTargetInfo(target)
                return info and info[FLD_STRUCT_BASE]
            end;

            --- Get the custom structure's default value
            -- @static
            -- @method  GetDefault
            -- @owner   struct
            -- @param   structure                   the structure
            -- @return  value                       the default value
            ["GetDefault"]      = function(target)
                local info      = getStructTargetInfo(target)
                return info and info[FLD_STRUCT_DEFAULT]
            end;

            --- Get the definition context of the struct
            -- @static
            -- @method  GetDefault
            -- @return  prototype                   the context type
            ["GetDefinitionContext"] = function() return structbuilder end;

            --- Generate an error message with template and target
            -- @static
            -- @method  GetErrorMessage
            -- @owner   struct
            -- @param   template                    the error message template, normally generated by type validation
            -- @param   target                      the target string, like "value"
            -- @return  string                      the error message
            ["GetErrorMessage"] = function(template, target)
                return strgsub(template, "%%s%.?", target)
            end;

            --- Get the member of the structure with given name
            -- @static
            -- @method  GetMember
            -- @owner   struct
            -- @param   structure                   the structure
            -- @param   name                        the member's name
            -- @return  member                      the member
            ["GetMember"]       = function(target, name)
                local info      = getStructTargetInfo(target)
                if info then
                    for _, m in ipairs, info, FLD_STRUCT_MEMBERSTART - 1 do
                        if m[FLD_MEMBER_NAME] == name then
                            return m[FLD_MEMBER_OBJ]
                        end
                    end
                end
            end;

            --- Get the members of the structure
            -- @static
            -- @method  GetMembers
            -- @owner   struct
            -- @format  (structure[, cache])
            -- @param   structure                   the structure
            -- @param   cache                       the table used to save the result
            -- @rformat (cache)                     the cache that contains the member list
            -- @rformat (iter, struct)              without the cache parameter, used in generic for
            ["GetMembers"]      = function(target, cache)
                local info      = getStructTargetInfo(target)
                if info then
                    if cache then
                        cache   = type(cache) == "table" and wipe(cache) or {}
                        for _, m in ipairs, info, FLD_STRUCT_MEMBERSTART - 1 do
                            tinsert(cache, m[FLD_MEMBER_OBJ])
                        end
                        return cache
                    else
                        return function(self, i)
                            i   = i and (i + 1) or FLD_STRUCT_MEMBERSTART
                            if info[i] then
                                return i, info[i][FLD_MEMBER_OBJ]
                            end
                        end, target
                    end
                end
                if cache then
                    return type(cache) == "table" and cache or nil
                else
                    return fakefunc, target
                end
            end;

            --- Get the method of the structure with given name
            -- @static
            -- @method  GetMethod
            -- @owner   struct
            -- @param   structure                   the structure
            -- @param   name                        the method's name
            -- @rformat method, isstatic
            -- @return  method                      the method
            -- @return  isstatic:boolean            whether the method is static
            ["GetMethod"]       = function(target, name)
                local info, def = getStructTargetInfo(target)
                if info and type(name) == "string" then
                    local mtd   = info[name]
                    if mtd then return mtd, true end
                    mtd         = info[FLD_STRUCT_TYPEMETHOD] and info[FLD_STRUCT_TYPEMETHOD][name]
                    if mtd then return mtd, false end
                end
            end;

            --- Get all the methods of the structure
            -- @static
            -- @method  GetMethods
            -- @owner   struct
            -- @format  (structure[, cache])
            -- @param   structure                   the structure
            -- @param   cache                       the table used to save the result
            -- @rformat (cache)                     the cache that contains the method list
            -- @rformat (iter, struct)              without the cache parameter, used in generic for
            -- @usage   for name, func, isstatic in struct.GetMethods(System.Drawing.Color) do
            --              print(name)
            --          end
            ["GetMethods"]      = function(target, cache)
                local info      = getStructTargetInfo(target)
                if info then
                    local typm  = info[FLD_STRUCT_TYPEMETHOD]
                    if cache then
                        cache   = type(cache) == "table" and wipe(cache) or {}
                        if typm then for k, v in pairs, typm do cache[k] = v or info[k] end end
                        return cache
                    elseif typm then
                        return function(self, n)
                            local m, v = next(typm, n)
                            if m then return m, v or info[m], not v end
                        end, target
                    end
                end
                if cache then
                    return type(cache) == "table" and cache or nil
                else
                    return fakefunc, target
                end
            end;

            --- Get the struct type of the structure
            -- @static
            -- @method  GetStructType
            -- @owner   struct
            -- @param   structure                   the structure
            -- @return  string                      the structure's type: CUSTOM|ARRAY|MEMBER
            ["GetStructType"]   = function(target)
                local info      = getStructTargetInfo(target)
                if info then
                    if info[FLD_STRUCT_ARRAY] then return STRUCT_TYPE_ARRAY end
                    if info[FLD_STRUCT_MEMBERSTART] then return STRUCT_TYPE_MEMBER end
                    return STRUCT_TYPE_CUSTOM
                end
            end;

            --- Whether the struct's value is immutable through the validation, means no object method, no initializer
            -- @static
            -- @method  IsImmutable
            -- @owner   struct
            -- @param   structure                   the structure
            -- @return  boolean                     true if the value should be immutable
            ["IsImmutable"]     = function(target)
                local info      = getStructTargetInfo(target)
                return info and validateFlags(MOD_IMMUTABLE_STRUCT, info[FLD_STRUCT_MOD]) or false
            end;

            --- Whether a structure use the other as its base structure
            -- @static
            -- @method  IsSubType
            -- @owner   struct
            -- @param   structure                   the structure
            -- @param   base                        the base structure
            -- @return  boolean                     true if the structure use the target structure as base
            ["IsSubType"]       = function(target, base)
                if struct.Validate(base) then
                    while target do
                        if target == base then return true end
                        local i = getStructTargetInfo(target)
                        target  = i and i[FLD_STRUCT_BASE]
                    end
                end
                return false
            end;

            --- Whether the structure is sealed, can't be re-defined
            -- @static
            -- @method  IsSealed
            -- @owner   struct
            -- @param   structure                   the structure
            -- @return  boolean                     true if the structure is sealed
            ["IsSealed"]        = function(target)
                local info      = getStructTargetInfo(target)
                return info and validateFlags(MOD_SEALED_STRUCT, info[FLD_STRUCT_MOD]) or false
            end;

            --- Whether the structure's given name method is static
            -- @static
            -- @method  IsStaticMethod
            -- @owner   struct
            -- @param   structure                   the structure
            -- @param   name                        the method's name
            -- @return  boolean                     true if the method is static
            ["IsStaticMethod"]  = function(target, name)
                local info      = getStructTargetInfo(target)
                return info and type(name) == "string" and info[FLD_STRUCT_TYPEMETHOD] and info[FLD_STRUCT_TYPEMETHOD][name] == false or false
            end;

            --- Set the structure's array element type
            -- @static
            -- @method  SetArrayElement
            -- @owner   struct
            -- @format  (structure, elementType[, stack])
            -- @param   structure                   the structure
            -- @param   elementType                 the element's type
            -- @param   stack                       the stack level
            ["SetArrayElement"] = function(target, eleType, stack)
                local info, def = getStructTargetInfo(target)
                stack           = parsestack(stack) + 1

                if info then
                    if not def then error(strformat("Usage: struct.SetArrayElement(structure, eleType[, stack]) - The %s's definition is finished", tostring(target)), stack) end
                    if info[FLD_STRUCT_MEMBERSTART] then error("Usage: struct.SetArrayElement(structure, eleType[, stack]) - The structure has member settings, can't set array element", stack) end

                    local tpValid = getprototypemethod(eleType, "ValidateValue")
                    if not tpValid then error("Usage: struct.SetArrayElement(structure, eleType[, stack]) - The element type is not valid", stack) end

                    info[FLD_STRUCT_ARRAY]      = eleType
                    info[FLD_STRUCT_ARRVALID]   = tpValid
                else
                    error("Usage: struct.SetArrayElement(structure, eleType[, stack]) - The structure is not valid", stack)
                end
            end;

            --- Set the structure's base structure
            -- @static
            -- @method  SetBaseStruct
            -- @owner   struct
            -- @format  (structure, base[, stack])
            -- @param   structure                   the structure
            -- @param   base                        the base structure
            -- @param   stack                       the stack level
            ["SetBaseStruct"]   = function(target, base, stack)
                local info, def = getStructTargetInfo(target)
                stack           = parsestack(stack) + 1

                if info then
                    if not def then error(strformat("Usage: struct.SetBaseStruct(structure, base) - The %s's definition is finished", tostring(target)), stack) end
                    if not struct.Validate(base) then error("Usage: struct.SetBaseStruct(structure, base) - The base must be a structure", stack) end
                    info[FLD_STRUCT_BASE] = base
                    attribute.InheritAttributes(target, ATTRTAR_STRUCT, base)
                else
                    error("Usage: struct.SetBaseStruct(structure, base[, stack]) - The structure is not valid", stack)
                end
            end;

            --- Set the structure's default value, only for custom struct type
            -- @static
            -- @method  SetDefault
            -- @owner   struct
            -- @format  (structure, default[, stack])
            -- @param   structure                   the structure
            -- @param   default                     the default value
            -- @param   stack                       the stack level
            ["SetDefault"]      = function(target, default, stack)
                local info, def = getStructTargetInfo(target)
                stack           = parsestack(stack) + 1

                if info then
                    if not def then error(strformat("Usage: struct.SetDefault(structure, default[, stack]) - The %s's definition is finished", tostring(target)), stack) end
                    info[FLD_STRUCT_DEFAULT] = default
                else
                    error("Usage: struct.SetDefault(structure, default[, stack]) - The structure is not valid", stack)
                end
            end;

            --- Set the structure's validator
            -- @static
            -- @method  SetValidator
            -- @owner   struct
            -- @format  (structure, func[, stack])
            -- @param   structure                   the structure
            -- @param   func                        the validator
            -- @param   stack                       the stack level
            ["SetValidator"]    = function(target, func, stack)
                local info, def = getStructTargetInfo(target)
                stack           = parsestack(stack) + 1

                if info then
                    if not def then error(strformat("Usage: struct.SetValidator(structure, validator[, stack]) - The %s's definition is finished", tostring(target)), stack) end
                    if type(func) ~= "function" then error("Usage: struct.SetValidator(structure, validator) - The validator must be a function", stack) end
                    info[FLD_STRUCT_VALIDSTART] = func
                else
                    error("Usage: struct.SetValidator(structure, validator[, stack]) - The structure is not valid", stack)
                end
            end;

            --- Set the structure's initializer
            -- @static
            -- @method  SetInitializer
            -- @owner   struct
            -- @format  (structure, func[, stack])
            -- @param   structure                   the structure
            -- @param   func                        the initializer
            -- @param   stack                       the stack level
            ["SetInitializer"]  = function(target, func, stack)
                local info, def = getStructTargetInfo(target)
                stack           = parsestack(stack) + 1

                if info then
                    if not def then error(strformat("Usage: struct.SetInitializer(structure, initializer[, stack]) - The %s's definition is finished", tostring(target)), stack) end
                    if type(func) ~= "function" then error("Usage: struct.SetInitializer(structure, initializer) - The initializer must be a function", stack) end
                    info[FLD_STRUCT_INITSTART] = func
                else
                    error("Usage: struct.SetInitializer(structure, initializer[, stack]) - The structure is not valid", stack)
                end
            end;

            --- Seal the structure
            -- @static
            -- @method  SetSealed
            -- @owner   struct
            -- @format  (structure[, stack])
            -- @param   structure                   the structure
            -- @param   stack                       the stack level
            ["SetSealed"]       = function(target, stack)
                local info      = getStructTargetInfo(target)
                stack           = parsestack(stack) + 1

                if info then
                    if not validateFlags(MOD_SEALED_STRUCT, info[FLD_STRUCT_MOD]) then
                        info[FLD_STRUCT_MOD] = turnOnFlags(MOD_SEALED_STRUCT, info[FLD_STRUCT_MOD])
                    end
                else
                    error("Usage: struct.SetSealed(structure[, stack]) - The structure is not valid", stack)
                end
            end;

            --- Mark a structure's method as static
            -- @static
            -- @method  SetStaticMethod
            -- @owner   struct
            -- @format  (structure, name[, stack])
            -- @param   structure                   the structure
            -- @param   name                        the method's name
            -- @param   stack                       the stack level
            ["SetStaticMethod"] = function(target, name, stack)
                local info, def = getStructTargetInfo(target)
                stack           = parsestack(stack) + 1

                if info then
                    if type(name) ~= "string" then error("Usage: struct.SetStaticMethod(structure, name) - the name must be a string", stack) end
                    name = strtrim(name)
                    if name == "" then error("Usage: Usage: struct.SetStaticMethod(structure, name) - The name can't be empty", stack) end
                    if not def then error(strformat("Usage: struct.SetStaticMethod(structure, name) - The %s's definition is finished", tostring(target)), stack) end

                    if info[name] == nil then
                        info[FLD_STRUCT_TYPEMETHOD] = info[FLD_STRUCT_TYPEMETHOD] or {}
                        info[name] = info[FLD_STRUCT_TYPEMETHOD][name]
                        info[FLD_STRUCT_TYPEMETHOD][name] = false
                    end
                else
                    error("Usage: struct.SetStaticMethod(structure, name[, stack]) - The structure is not valid", stack)
                end
            end;

            --- Validate the value with a structure
            -- @static
            -- @method  ValidateValue
            -- @owner   struct
            -- @format  (structure, value[, onlyValid[, stack]])
            -- @param   structure                   the structure
            -- @param   value                       the value used to validate
            -- @param   onlyValid                   Only validate the value, no value modifiy(The initializer and object methods won't be applied)
            -- @param   stack                       the stack level
            -- @rfomat  (value[, message])
            -- @return  value                       the validated value
            -- @return  message                     the error message if the validation is failed
            ["ValidateValue"]   = function(target, value, onlyValid, cache)
                local info  = _StructInfo[target]
                if info then
                    if not cache and info[FLD_STRUCT_VALIDCACHE] then
                        cache = _Cache()
                        local ret, msg = info[FLD_STRUCT_VALID](info, value, onlyValid, cache)
                        for k, v in pairs, cache do cache[k] = nil _Cache(v) end _Cache(cache)
                        return ret, msg
                    else
                        return info[FLD_STRUCT_VALID](info, value, onlyValid, cache)
                    end
                else
                    error("Usage: struct.ValidateValue(structure, value[, onlyValid]) - The structure is not valid", 2)
                end
            end;

            -- Whether the value is a struct type
            -- @static
            -- @method  Validate
            -- @owner   struct
            -- @param   value                       the value used to validate
            -- @return  value                       return the value if it's a struct type, otherwise nil will be return
            ["Validate"]        = function(target)
                return getmetatable(target) == struct and target or nil
            end;
        },
        __newindex              = readOnly,
        __call                  = function(self, ...)
            local visitor, env, target, definition, keepenv, stack  = getTypeParams(struct, tstruct, ...)
            if not target then error("Usage: struct([env, ][name, ][definition, ][keepenv, ][stack]) - the struct type can't be created", stack) end

            stack           = stack + 1

            struct.BeginDefinition(target, stack)

            Debug("[struct] %s created", stack, tostring(target))

            local builder   = prototype.NewObject(structbuilder)
            environment.Initialize  (builder)
            environment.SetNamespace(builder, target)
            environment.SetParent   (builder, env)

            _StructBuilderInDefine  = saveStorage(_StructBuilderInDefine, builder, true)

            if definition then
                builder(definition, stack)
                return target
            else
                if not keepenv then safesetfenv(stack, builder) end
                return builder
            end
        end,
    }

    tstruct                     = prototype (tnamespace, {
        __index                 = function(self, name)
            if type(name) == "string" then
                local info  = _StructBuilderInfo[self] or _StructInfo[self]
                return info and (info[name] or info[FLD_STRUCT_TYPEMETHOD] and info[FLD_STRUCT_TYPEMETHOD][name]) or namespace.GetNamespace(self, name)
            end
        end,
        __call                  = function(self, ...)
            local info  = _StructInfo[self]
            local ret   = info[FLD_STRUCT_CTOR](info, ...)
            return ret
        end,
        __metatable             = struct,
    })

    structbuilder               = prototype {
        __tostring              = function(self)
            local owner         = environment.GetNamespace(self)
            return"[structbuilder]" .. (owner and tostring(owner) or "anonymous")
        end,
        __index                 = function(self, key)
            local value         = getEnvValue(self, key, _StructBuilderInDefine[self], 2)
            return value
        end,
        __newindex              = function(self, key, value)
            if not setStructBuilderValue(self, key, value, 2) then
                return rawset(self, key, value)
            end
        end,
        __call                  = function(self, definition, stack)
            stack               = parsestack(stack) + 1
            if not definition then error("Usage: struct([env, ][name, ][stack]) (definition) - the definition is missing", stack) end

            local owner = environment.GetNamespace(self)
            if not (owner and _StructBuilderInDefine[self] and _StructBuilderInfo[owner]) then error("The struct's definition is finished", stack) end

            definition = parseDefinition(attribute.InitDefinition(owner, ATTRTAR_STRUCT, definition, nil, nil, stack), self, stack)

            if type(definition) == "function" then
                setfenv(definition, self)
                definition(self)
            else
                -- Check base struct first
                if definition[STRUCT_KEYWORD_BASE] ~= nil then
                    setStructBuilderValue(self, STRUCT_KEYWORD_BASE, definition[STRUCT_KEYWORD_BASE], stack, true)
                    definition[STRUCT_KEYWORD_BASE] = nil
                end

                -- Index key
                for i, v in ipairs, definition, 0 do
                    setStructBuilderValue(self, i, v, stack, true)
                end

                for k, v in pairs, definition do
                    if type(k) == "string" then
                        setStructBuilderValue(self, k, v, stack, true)
                    end
                end
            end

            _StructBuilderInDefine = saveStorage(_StructBuilderInDefine, self, nil)
            struct.EndDefinition(owner, stack)

            if getfenv(stack) == self then
                safesetfenv(stack, environment.GetParent(self) or _G)
            end

            return owner
        end,
    }

    -----------------------------------------------------------------------
    --                             keywords                              --
    -----------------------------------------------------------------------

    -----------------------------------------------------------------------
    -- Declare a new member for the structure
    --
    -- @keyword     member
    -- @usage       member "Name" { Type = String, Default = "Anonymous", Require = false }
    -----------------------------------------------------------------------
    member                      = prototype {
        __tostring              = function(self) local info = _MemberInfo[self] return info and info[FLD_MEMBER_NAME] end,
        __index                 = {
            -- Get the type of the member
            -- @static
            -- @method  GetType
            -- @owner   member
            -- @param   target                      the member
            -- @return  type                        the member's type
            ["GetType"]         = function(self) local info = _MemberInfo[self] return info and info[FLD_MEMBER_TYPE] end;

            -- Whether the member's value is required
            -- @static
            -- @method  IsRequire
            -- @owner   member
            -- @param   target                      the member
            -- @return  type                        the member's type
            ["IsRequire"]       = function(self) local info = _MemberInfo[self] return info and info[FLD_MEMBER_REQUIRE] or false end;

            -- Get the name of the member
            -- @static
            -- @method  GetName
            -- @owner   member
            -- @param   target                      the member
            -- @return  name                        the member's name
            ["GetName"]         = function(self) local info = _MemberInfo[self] return info and info[FLD_MEMBER_NAME] end;

            -- Get the default value of the member
            -- @static
            -- @method  GetDefault
            -- @owner   member
            -- @param   target                      the member
            -- @return  default                     the member's default value
            ["GetDefault"]      = function(self) local info = _MemberInfo[self] return info and info[FLD_MEMBER_DEFAULT] end;
        },
        __newindex              = readOnly,
        __call                  = function(self, ...)
            if self == member then
                local visitor, env, name, definition, flag, stack  = getFeatureParams(member, nil, ...)
                local owner = visitor and environment.GetNamespace(visitor)

                if owner and name then
                    if type(definition) == "table" then
                        _MemberAccessOwner  = nil
                        _MemberAccessName   = nil
                        struct.AddMember(owner, name, definition, stack + 1)
                        return
                    else
                        _MemberAccessOwner = owner
                        _MemberAccessName  = name
                        return self
                    end
                elseif type(definition) == "table" then
                    name    = _MemberAccessName
                    owner   = owner or _MemberAccessOwner

                    _MemberAccessOwner  = nil
                    _MemberAccessName   = nil

                    if owner then
                        if name then
                            struct.AddMember(owner, name, definition, stack + 1)
                        else
                            struct.AddMember(owner, definition, stack + 1)
                        end
                        return
                    end
                end

                error([[Usage: member "name" {...}]], stack + 1)
            end
        end,
    }

    -----------------------------------------------------------------------
    -- Set the array element to the structure
    --
    -- @keyword     array
    -- @usage       array "Object"
    -----------------------------------------------------------------------
    array                       = function (...)
        local visitor, env, name, _, flag, stack  = getFeatureParams(array, namespace, ...)

        name = parseNamespace(name, visitor, env)
        if not name then error("Usage: array(type) - The type is not provided", stack + 1) end

        local owner = visitor and environment.GetNamespace(visitor)
        if not owner  then error("Usage: array(type) - The system can't figure out the structure", stack + 1) end

        struct.SetArrayElement(owner, name)
    end

    -----------------------------------------------------------------------
    -- End the definition of the structure
    --
    -- @keyword     endstruct
    -- @usage       struct "Number"
    --                  function Number(val)
    --                      return type(val) ~= "number" and "%s must be number"
    --                  end
    --              endstruct "Number"
    -----------------------------------------------------------------------
    endstruct                   = PLOOP_PLATFORM_SETTINGS.TYPE_DEFINITION_WITH_OLD_STYLE and function (...)
        local visitor, env, name, definition, flag, stack  = getFeatureParams(endstruct, nil,  ...)
        local owner = visitor and environment.GetNamespace(visitor)

        stack = stack + 1

        if not owner or not visitor then error([[Usage: endstruct "name" - can't be used here.]], stack) end
        if namespace.GetNamespaceName(owner, true) ~= name then error(strformat("%s's definition isn't finished", tostring(owner)), stack) end

        _StructBuilderInDefine = saveStorage(_StructBuilderInDefine, visitor, nil)
        struct.EndDefinition(owner, stack)

        local baseEnv       = environment.GetParent(visitor) or _G

        setfenv(stack, baseEnv)

        return baseEnv
    end or nil
end

-------------------------------------------------------------------------------
-- The classes are types that abstracted from a group of similar objects. The
-- objects generated by the classes are tables with fixed meta-tables.
--
-- A class can be defined within several parts:
--
-- i. **Method**        The methods are functions that be used by the classes
--          and their objects. Take an example :
--
--              class "Person" (function(_ENV)
--                  function SetName(self, name)
--                      self.name = name
--                  end
--
--                  function GetName(self, name)
--                      return self.name
--                  end
--              end)
--
--              Ann = Person()
--              Ann:SetName("Ann")
--              print("Hello " .. Ann:GetName()) -- Hello Ann
--
-- Like the struct, the definition body of the class _Person_ also should be a
-- function with `_ENV` as its first parameter. In the definition, the global
-- delcared functions will be registered as the class's method. Those functions
-- should use _self_ as the first parameter to receive the objects.
--
-- When the definition is done, the class object's meta-table is auto-generated
-- based on the class's definition layout. For the _Person_ class, it should be
--
--              {
--                  __index = { SetName = function, GetName = function },
--                  __metatable = Person,
--              }
--
-- The class can access the object method directly, and also could have their
-- own method - static method:
--
--              class "Color" (function(_ENV)
--                  __Static__()
--                  function FromRGB(r, g, b)
--                      -- The object construct will be talked later
--                      return Color {r = r, g = g, b = b}
--                  end
--              end)
--
--              c = Color.FromRGB(1, 0, 1)
--              print(c.r, c.g, c.b)
--
-- The static method don't use _self_ as the first parameter since it's used by
-- the class itself not its objects.
--
-- ii. **Meta-data**    The meta-data is a superset of the Lua's meta-method:
--          *  __add        the addition operation:             a + b  -- a is the object, also for the below operations
--          *  __sub        the subtraction operation:          a - b
--          *  __mul        the multiplication operation:       a * b
--          *  __div        the division operation:             a / b
--          *  __mod        the modulo operation:               a % b
--          *  __pow        the exponentiation operation:       a ^ b
--          *  __unm        the negation operation:             - a
--          *  __idiv       the floor division operation:       a // b
--          *  __band       the bitwise AND operation:          a & b
--          *  __bor        the bitwise OR operation:           a | b
--          *  __bxor       the bitwise exclusive OR operation: a~b
--          *  __bnot       the bitwise NOToperation:           ~a
--          *  __shl        the bitwise left shift operation:   a<<b
--          *  __shr        the bitwise right shift operation:  a>>b
--          *  __concat     the concatenation operation:        a..b
--          *  __len        the length operation:               #a
--          *  __eq         the equal operation:                a == b
--          *  __lt         the less than operation:            a < b
--          *  __le         the less equal operation:           a <= b
--          *  __index      The indexing access:                return a[k]
--          *  __newindex   The indexing assignment:            a[k] = v
--          *  __call       The call operation:                 a(...)
--          *  __gc         the garbage-collection
--          *  __tostring   the convert to string operation:    tostring(a)
--          *  __ipairs     the ipairs iterator:                ipairs(a)
--          *  __pairs      the pairs iterator:                 pairs(a)
--          *  __exist      the object existence checker
--          *  __field      the init object fields, must be a table
--          *  __new        the function used to generate the table that'd be converted to an object
--          *  __ctor       the object constructor
--          *  __dtor       the object destructor
--
--  There are several PLoop special meta-data, here are examples :
--
--              class "Person" (function(_ENV)
--                  __ExistPerson = {}
--
--                  -- The Constructor
--                  function __ctor(self, name)
--                      print("Call the Person's constructor with " .. name)
--                      __ExistPerson[name] = self
--                      self.name = name
--                  end
--
--                  -- The existence checker
--                  function __exist(name)
--                      if __ExistPerson[name] then
--                          print("An object existed with " .. name)
--                          return __ExistPerson[name]
--                      end
--                  end
--
--                  -- The destructor
--                  function __dtor(self)
--                      print("Dispose the object " .. self.name)
--                      __ExistPerson[self.name] = nil
--                  end
--              end)
--
--              o = Person("Ann")           -- Call the Person's constructor with Ann
--
--              -- true
--              print(o == Person("Ann"))   -- An object existed with Ann
--
--              o:Dispose()                 -- Dispose the object Ann
--
--              -- false
--              print(o == Person("Ann")) -- Call the Person's constructor with Ann
--
-- Here is the constructor, the destructor and an existence checker. We also
-- can find a non-declared method **Dispose**, all objects generated by classes
-- have the **Dispose** method, used to call it's class, super class and the
-- class's extended interface's destructor with order to destruct the object,
-- normally the destructor is used to release the reference of the object, so
-- the Lua can collect them.
--
-- The constructor receive the object and all the parameters, the existence
-- checker receive all the parameters, and if it return a non-false value, the
-- value will be used as the object and return it directly. The destructor only
-- receive the object.
--
-- The `__new` meta is used to generate table that will be used as the object.
-- You can use it to return tables generated by other systems or you can return
-- a well inited table so the object's construction speed will be greatly
-- increased like :
--
--              class "List" (function(_ENV)
--                  function __new(...)
--                      return { ... }
--                  end
--              end)
--
--              v = List(1, 2, 3, 4, 5, 6)
--
-- The `__new` would recieve all parameters and return a table and a boolean
-- value, if the value is true, all parameters will be discarded so won't pass
-- to the constructor. So for the List class, the `__new` meta will eliminate
-- the rehash cost of the object's initialization.
--
-- The `__field` meta is a table, contains several key-value paris to be saved
-- in the object, normally it's used with the **OBJECT_NO_RAWSEST** and the
-- **OBJECT_NO_NIL_ACCESS** options, so authors can only use existing fields to
-- to the jobs, and spell errors can be easily spotted.
--
--              PLOOP_PLATFORM_SETTINGS = { OBJECT_NO_RAWSEST   = true, OBJECT_NO_NIL_ACCESS= true, }
--
--              require "PLoop"
--
--              class "Person" (function(_ENV)
--                  __field     = {
--                      name    = "noname",
--                  }
--
--                  -- Also you can use *field* keyword since `__field` could be error spelled
--                  field {
--                      age     = 0,
--                  }
--              end)
--
--              o = Person()
--              o.name = "Ann"
--              o.age  = 12
--
--              o.nme = "King"  -- Error : The object can't accept field that named "nme"
--              print(o.gae)    -- Error : The object don't have any field that named "gae"
--
-- For the constructor and destructor, there are other formal names: the class
-- name will be used as constructor, and the **Dispose** will be used as the
-- destructor:
--
--              class "Person" (function(_ENV)
--                  -- The Constructor
--                  function Person(self, name)
--                      self.name = name
--                  end
--
--                  -- The destructor
--                  function Dispose(self)
--                  end
--              end)
--
--
-- iii. **Super class** the class can and only can have one super class, the
-- class will inherit the super class's object method, meta-datas and other
-- features(event, property and etc). If the class has override the super's
-- object method, meta-data or other features, the class can use **super**
-- keyword to access the super class's method, meta-data or feature.
--
--              class "A" (function(_ENV)
--                  -- Object method
--                  function Test(self)
--                      print("Call A's method")
--                  end
--
--                  -- Constructor
--                  function A(self)
--                      print("Call A's ctor")
--                  end
--
--                  -- Destructor
--                  function Dispose(self)
--                      print("Dispose A")
--                  end
--
--                  -- Meta-method
--                  function __call(self)
--                      print("Call A Object")
--                  end
--              end)
--
--              class "B" (function(_ENV)
--                  inherit "A"  -- also can use inherit(A)
--
--                  function Test(self)
--                      print("Call super's method ==>")
--                      super[self]:Test()
--                      super.Test(self)
--                      print("Call super's method ==<")
--                  end
--
--                  function B(self)
--                      super(self)
--                      print("Call B's ctor")
--                  end
--
--                  function Dispose(self)
--                      print("Dispose B")
--                  end
--
--                  function __call(self)
--                      print("Call B Object")
--                      super[self]:__call()
--                      super.__call(self)
--                  end
--              end)
--
--              -- Call A's ctor
--              -- Call B's ctor
--              o = B()
--
--              -- Call super's method ==>
--              -- Call A's method
--              -- Call A's method
--              -- Call super's method ==<
--              o:Test()
--
--              -- Call B Object
--              -- Call A Object
--              -- Call A Object
--              o()
--
--              -- Dispose B
--              -- Dispose A
--              o:Dispose()
--
-- From the example, here are some details:
--      * The destructor don't need call super's destructor, they are well
--  controlled by the system, so the class only need to consider itself.
--      * The constructor need call super's constructor manually, we'll learned
--  more about it within the overload system.
--      * For the object method and meta-method, we have two style to call its
--  super, `super.Test(self)` is a simple version, but if the class has multi
--  versions, we must keep using the `super[self]:Test()` code style, because
--  the super can know the object's class version before it fetch the *Test*
--  method. We'll see more about the super call style in the event and property
--  system.
--
-- @prototype   class
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- The interfaces are abstract types of functionality, it also provided the
-- multi-inheritance mechanism to the class. Like the class, it also support
-- object method, static method and meta-datas.
--
-- The class and interface can extend many other interfaces, the **super**
-- keyword also can access the extended interface's object-method and the
-- meta-methods.
--
-- The interface use `__init` instead of the `__ctor` as the interface's
-- initializer. The initializer only receive the object as it's parameter, and
-- don't like the constructor, the initializer can't be accessed by **super**
-- keyword. The method defined with the interface's name will also be used as
-- the initializer.
--
-- If you only want defined methods and features that should be implemented by
-- child interface or class, you can use `__Abstract__` on the method or the
-- feature, those abstract methods and featuers can't be accessed by **super**
-- keyword.
--
-- Let's take an example :
--
--              interface "IName" (function(self)
--                  __Abstract__()
--                  function SetName(self) end
--
--                  __Abstract__()
--                  function GetName(self) end
--
--                  -- initializer
--                  function IName(self) print("IName Init") end
--
--                  -- destructor
--                  function Dispose(self) print("IName Dispose") end
--              end)
--
--              interface "IAge" (function(self)
--                  __Abstract__()
--                  function SetAge(self) end
--
--                  __Abstract__()
--                  function GetAge(self) end
--
--                  -- initializer
--                  function IAge(self) print("IAge Init") end
--
--                  -- destructor
--                  function Dispose(self) print("IAge Dispose") end
--              end)
--
--              class "Person" (function(_ENV)
--                  extend "IName" "IAge"   -- also can use `extend(IName)(IAge)`
--
--                  -- Error: attempt to index global 'super' (a nil value)
--                  -- Since there is no super method(the IName.SetName is abstract),
--                  -- there is no super keyword can be use
--                  function SetName(self, name) super[self]:SetName(name) end
--
--                  function Person(self) print("Person Init") end
--
--                  function Dispose(self) print("Person Dispose") end
--              end)
--
--              -- Person Init
--              -- IName Init
--              -- IAge Init
--              o = Person()
--
--              -- IAge Dispose
--              -- IName Dispose
--              -- Person Dispose
--              o:Dispose()
--
-- From the example, we can see the initializers are called when object is
-- created and already passed the class's constructor. The dispose order is
-- the reverse order of the object creation. So, the class and interface should
-- only care themselves.
--
-- @prototype   interface
-------------------------------------------------------------------------------
do
    -----------------------------------------------------------------------
    --                         attribute targets                         --
    -----------------------------------------------------------------------
    ATTRTAR_INTERFACE           = attribute.RegisterTargetType("Interface")
    ATTRTAR_CLASS               = attribute.RegisterTargetType("Class")
    ATTRTAR_METHOD              = rawget(_PLoopEnv, "ATTRTAR_METHOD") or attribute.RegisterTargetType("Method")

    -----------------------------------------------------------------------
    --                         private constants                         --
    -----------------------------------------------------------------------
    -- FEATURE MODIFIER
    local MOD_SEALED_IC         = newflags(true)    -- SEALED TYPE
    local MOD_FINAL_IC          = newflags()        -- FINAL TYPE
    local MOD_ABSTRACT_CLS      = newflags()        -- ABSTRACT CLASS
    local MOD_SINGLEVER_CLS     = newflags()        -- SINGLE VERSION CLASS - NO MULTI VERSION
    local MOD_ATTRFUNC_OBJ      = newflags()        -- ENABLE FUNCTION ATTRIBUTE ON OBJECT
    local MOD_NORAWSET_OBJ      = newflags()        -- NO RAW SET FOR OBJECTS
    local MOD_NONILVAL_OBJ      = newflags()        -- NO NIL dFIELD ACCESS
    local MOD_NOSUPER_OBJ       = newflags()        -- OLD SUPER ACCESS STYLE
    local MOD_ANYMOUS_CLS       = newflags()        -- HAS ANONYMOUS CLASS

    local MOD_INITVAL_CLS       = (PLOOP_PLATFORM_SETTINGS.CLASS_NO_MULTI_VERSION_CLASS  and MOD_SINGLEVER_CLS or 0) +
                                  (PLOOP_PLATFORM_SETTINGS.CLASS_NO_SUPER_OBJECT_STYLE   and MOD_NOSUPER_OBJ   or 0) +
                                  (PLOOP_PLATFORM_SETTINGS.OBJECT_NO_RAWSEST             and MOD_NORAWSET_OBJ  or 0) +
                                  (PLOOP_PLATFORM_SETTINGS.OBJECT_NO_NIL_ACCESS          and MOD_NONILVAL_OBJ  or 0)

    local MOD_INITVAL_IF        = (PLOOP_PLATFORM_SETTINGS.INTERFACE_ALL_ANONYMOUS_CLASS and MOD_ANYMOUS_CLS   or 0)

    local INI_FLD_DEBUGSR       = PLOOP_PLATFORM_SETTINGS.OBJECT_DEBUG_SOURCE or nil

    -- STATIC FIELDS
    local FLD_IC_STEXT          =  1                -- FIELD EXTEND INTERFACE START INDEX(keep 1 so we can use unpack on it)
    local FLD_IC_SUPCLS         =  0                -- FIELD SUPER CLASS
    local FLD_IC_MOD            = -1                -- FIELD MODIFIER
    local FLD_IC_CTOR           = -2                -- FIELD CONSTRUCTOR|INITIALIZER
    local FLD_IC_DTOR           = -3                -- FIELD DESTRUCTOR
    local FLD_IC_FIELD          = -4                -- FIELD INIT FIELDS
    local FLD_IC_EXIST          = -5                -- FIELD EXIST OBJECT CHECK
    local FLD_IC_NEWOBJ         = -6                -- FIELD NEW OBJECT
    local FLD_IC_TYPMTD         = -7                -- FIELD TYPE METHODS
    local FLD_IC_TYPMTM         = -8                -- FIELD TYPE META-METHODS
    local FLD_IC_TYPFTR         = -9                -- FILED TYPE FEATURES
    local FLD_IC_INHRTP         =-10                -- FIELD INHERITANCE PRIORITY
    local FLD_IC_REQCLS         =-11                -- FIELD REQUIR CLASS FOR INTERFACE
    local FLD_IC_SUPER          =-12                -- FIELD SUPER
    local FLD_IC_THIS           =-13                -- FIELD THIS
    local FLD_IC_ANYMSCL        =-14                -- FIELD ANONYMOUS CLASS FOR INTERFACE
    local FLD_IC_DEBUGSR        =-15                -- FIELD WHETHER DEBUG THE OBJECT SOURCE

    -- CACHE FIELDS
    local FLD_IC_STAFTR         =-16                -- FIELD STATIC TYPE FEATURES
    local FLD_IC_OBJMTD         =-17                -- FIELD OBJECT METHODS
    local FLD_IC_OBJMTM         =-18                -- FIELD OBJECT META-METHODS
    local FLD_IC_OBJFTR         =-19                -- FIELD OBJECT FEATURES
    local FLD_IC_OBJFLD         =-20                -- FIELD OBJECT INIT-FIELDS
    local FLD_IC_OBJEXT         =-21                -- FIELD OBJECT EXIST CHECK
    local FLD_IC_OBJNEW         =-22                -- FIELD OBJECT NEW OBJECT
    local FLD_IC_ONEABS         =-23                -- FIELD ONE ABSTRACT-METHOD INTERFACE
    local FLD_IC_SUPINFO        =-24                -- FIELD INFO CACHE FOR SUPER CLASS & EXTEND INTERFACES
    local FLD_IC_SUPMTD         =-25                -- FIELD SUPER METHOD & META-METHODS
    local FLD_IC_SUPFTR         =-26                -- FIELD SUPER FEATURE

    -- Ctor & Dispose
    local FLD_IC_OBCTOR         = 10000             -- FIELD THE OBJECT CONSTRUCTOR
    local FLD_IC_CLINIT         = FLD_IC_OBCTOR + 1 -- FEILD THE CLASS INITIALIZER
    local FLD_IC_ENDISP         = FLD_IC_OBCTOR - 1 -- FIELD ALL EXTEND INTERFACE DISPOSE END INDEX
    local FLD_IC_STINIT         = FLD_IC_CLINIT + 1 -- FIELD ALL EXTEND INTERFACE INITIALIZER START INDEX

    -- Inheritance priority
    local INRT_PRIORITY_FINAL   =  1
    local INRT_PRIORITY_NORMAL  =  0
    local INRT_PRIORITY_ABSTRACT= -1

    -- Flags for object accessing
    local FLG_IC_OBJMTD         = newflags(true)    -- HAS OBJECT METHOD
    local FLG_IC_OBJFTR         = newflags()        -- HAS OBJECT FEATURE
    local FLG_IC_IDXFUN         = newflags()        -- HAS INDEX FUNCTION
    local FLG_IC_IDXTBL         = newflags()        -- HAS INDEX TABLE
    local FLG_IC_NEWIDX         = newflags()        -- HAS NEW INDEX
    local FLG_IC_OBJATR         = newflags()        -- ENABLE OBJECT METHOD ATTRIBUTE
    local FLG_IC_NRAWST         = newflags()        -- ENABLE NO RAW SET
    local FLG_IC_NNILVL         = newflags()        -- NO NIL VALUE ACCESS
    local FLG_IC_SUPACC         = newflags()        -- SUPER OBJECT ACCESS

    -- Flags for constructor
    local FLG_IC_EXIST          = newflags(FLG_IC_IDXFUN)   -- HAS __exist
    local FLG_IC_NEWOBJ         = newflags()        -- HAS __new
    local FLG_IC_FIELD          = newflags()        -- HAS __field
    local FLG_IC_HSCLIN         = newflags()        -- HAS CLASS INITIALIZER
    local FLG_IC_HSIFIN         = newflags()        -- NEED CALL INTERFACE'S INITIALIZER

    -- Meta Datas
    local IC_META_DISPOB        = "Dispose"
    local IC_META_EXIST         = "__exist"         -- Existed objecj check
    local IC_META_FIELD         = "__field"         -- Init fields
    local IC_META_NEW           = "__new"           -- New object
    local IC_META_CTOR          = "__ctor"          -- Constructor
    local IC_META_DTOR          = "__dtor"          -- Destructor, short for Dispose
    local IC_META_INIT          = "__init"          -- Initializer

    local IC_META_INDEX         = "__index"
    local IC_META_NEWIDX        = "__newindex"
    local IC_META_TABLE         = "__metatable"

    -- Super & This
    local IC_KEYWORD_SUPER      = "super"
    local IC_KEYWORD_THIS       = "this"
    local OBJ_SUPER_ACCESS      = "__PLOOP_SUPER_ACCESS"

    -- Type Builder
    local IC_BUILDER_NEWMTD     = "__PLOOP_BD_NEWMTD"

    local META_KEYS             = {
        __add                   = "__add",          -- a + b
        __sub                   = "__sub",          -- a - b
        __mul                   = "__mul",          -- a * b
        __div                   = "__div",          -- a / b
        __mod                   = "__mod",          -- a % b
        __pow                   = "__pow",          -- a ^ b
        __unm                   = "__unm",          -- - a
        __idiv                  = "__idiv",         -- // floor division
        __band                  = "__band",         -- & bitwise and
        __bor                   = "__bor",          -- | bitwise or
        __bxor                  = "__bxor",         -- ~ bitwise exclusive or
        __bnot                  = "__bnot",         -- ~ bitwise unary not
        __shl                   = "__shl",          -- << bitwise left shift
        __shr                   = "__shr",          -- >> bitwise right shift
        __concat                = "__concat",       -- a..b
        __len                   = "__len",          -- #a
        __eq                    = "__eq",           -- a == b
        __lt                    = "__lt",           -- a < b
        __le                    = "__le",           -- a <= b
        __index                 = "___index",       -- return a[b]
        __newindex              = "___newindex",    -- a[b] = v
        __call                  = "__call",         -- a()
        __gc                    = "__gc",           -- dispose a
        __tostring              = "__tostring",     -- tostring(a)
        __ipairs                = "__ipairs",       -- ipairs(a)
        __pairs                 = "__pairs",        -- pairs(a)

        -- Special meta keys
        [IC_META_DISPOB]        = FLD_IC_DTOR,
        [IC_META_DTOR]          = FLD_IC_DTOR,
        [IC_META_EXIST]         = FLD_IC_EXIST,
        [IC_META_FIELD]         = FLD_IC_FIELD,
        [IC_META_NEW]           = FLD_IC_NEWOBJ,
        [IC_META_CTOR]          = FLD_IC_CTOR,
        [IC_META_INIT]          = FLD_IC_CTOR,
    }

    -- UNSAFE FIELD
    local FLD_IC_META           = "__PLOOP_IC_META"
    local FLD_IC_TYPE           = "__PLOOP_IC_TYPE"
    local FLD_OBJ_SOURCE        = "__PLOOP_OBJ_SOURCE"

    -----------------------------------------------------------------------
    --                          private storage                          --
    -----------------------------------------------------------------------
    local _ICInfo               = PLOOP_PLATFORM_SETTINGS.UNSAFE_MODE
                                    and setmetatable({}, {__index = function(_, c) return type(c) == "table" and rawget(c, FLD_IC_META) or nil end})
                                    or  newStorage(WEAK_KEY)

    local _ThisMap              = PLOOP_PLATFORM_SETTINGS.UNSAFE_MODE
                                    and setmetatable({}, {__index = function(_, c) return type(c) == "table" and rawget(c, FLD_IC_TYPE) or nil end})
                                    or  newStorage(WEAK_ALL)
    local _SuperMap             = PLOOP_PLATFORM_SETTINGS.UNSAFE_MODE
                                    and setmetatable({}, {__index = function(_, c) return type(c) == "table" and rawget(c, FLD_IC_TYPE) or nil end})
                                    or  newStorage(WEAK_ALL)

    local _Parser               = {}

    -- TYPE BUILDING
    local _ICBuilderInfo        = newStorage(WEAK_KEY)      -- TYPE BUILDER INFO
    local _ICBuilderInDefine    = newStorage(WEAK_KEY)
    local _ICDependsMap         = {}                        -- CHILDREN MAP

    local _ICIndexMap           = {}
    local _ICNewIdxMap          = {}
    local _ClassCtorMap         = {}

    -----------------------------------------------------------------------
    --                          private helpers                          --
    -----------------------------------------------------------------------
    local getEnvValue           = environment.GetValue

    local getICTargetInfo       = function (target) local info  = _ICBuilderInfo[target] if info then return info, true else return _ICInfo[target], false end end

    local saveICInfo            = PLOOP_PLATFORM_SETTINGS.UNSAFE_MODE
                                    and function(target, info) rawset(target, FLD_IC_META, info) end
                                    or  function(target, info) _ICInfo = saveStorage(_ICInfo, target, info) end

    local saveThisMap           = PLOOP_PLATFORM_SETTINGS.UNSAFE_MOD
                                    and function(this, target) rawset(this, FLD_IC_TYPE, target) end
                                    or  function(this, target) _ThisMap = saveStorage(_ThisMap, this, target) end

    local saveSuperMap          = PLOOP_PLATFORM_SETTINGS.UNSAFE_MOD
                                    and function(super, target) rawset(super, FLD_IC_TYPE, target) end
                                    or  function(super, target) _SuperMap = saveStorage(_SuperMap, super, target) end

    -- Type Generator
    local iterSuperInfo         = function (info, reverse)
        if reverse then
            if info[FLD_IC_SUPCLS] then
                local scache    = _Cache()
                local scls      = info[FLD_IC_SUPCLS]
                while scls do
                    local sinfo = _ICInfo[scls]
                    tinsert(scache, sinfo)
                    scls        = sinfo[FLD_IC_SUPCLS]
                end

                local scnt      = #scache - FLD_IC_STEXT + 1
                return function(root, idx)
                    if idx >= FLD_IC_STEXT then
                        return idx - 1, _ICInfo[root[idx]], true
                    elseif scnt + idx > 0 then
                        return idx - 1, scache[scnt + idx], false
                    end
                    _Cache(scache)
                end, info, #info
            else
                return function(root, idx)
                    if idx >= FLD_IC_STEXT then
                        return idx - 1, _ICInfo[root[idx]], true
                    end
                end, info, #info
            end
        else
            return function(root, idx)
                if not tonumber(idx) then
                    local scls  = idx[FLD_IC_SUPCLS]
                    if scls then
                        idx     = _ICInfo[scls]
                        return idx, idx, false
                    end
                    idx         = FLD_IC_STEXT - 1
                end
                idx             = idx + 1
                local extif     = root[idx]
                if extif then return idx, _ICInfo[extif], true end
            end, info, info
        end
    end

    local getSuperOnPriority    = function (info, name, get)
        local minpriority, norpriority
        for _, sinfo in iterSuperInfo(info) do
            local m = get(sinfo, name)
            if m then
                local priority = sinfo[FLD_IC_INHRTP] and sinfo[FLD_IC_INHRTP][name] or INRT_PRIORITY_NORMAL
                if priority == INRT_PRIORITY_FINAL then
                    return m, INRT_PRIORITY_FINAL
                elseif priority == INRT_PRIORITY_ABSTRACT then
                    minpriority = minpriority or m
                else
                    norpriority = norpriority or m
                end
            end
        end
        if norpriority then
            return norpriority, INRT_PRIORITY_NORMAL
        elseif minpriority then
            return minpriority, INRT_PRIORITY_ABSTRACT
        end
    end

    local getTypeMethod         = function (info, name) info = info[FLD_IC_TYPMTD] return info and info[name] end

    local getTypeFeature        = function (info, name) info = info[FLD_IC_TYPFTR] return info and info[name] end

    local getTypeMetaMethod     = function (info, name) info = info[FLD_IC_TYPMTM] return info and info[META_KEYS[name]] end

    local getSuperMethod        = function (info, name) return getSuperOnPriority(info, name, getTypeMethod) end

    local getSuperFeature       = function (info, name) return getSuperOnPriority(info, name, getTypeFeature) end

    local getSuperMetaMethod    = function (info, name) return getSuperOnPriority(info, name, getTypeMetaMethod) end

    local genSuperOrderList
        genSuperOrderList       = function (info, lst, super)
        if info then
            local scls      = info[FLD_IC_SUPCLS]
            if scls then
                local sinfo = _ICInfo[scls]
                genSuperOrderList(sinfo, lst, super)
                if super and (sinfo[FLD_IC_SUPFTR] or sinfo[FLD_IC_SUPMTD]) then super[scls] = sinfo end
            end

            for i = #info, FLD_IC_STEXT, -1 do
                local extif = info[i]
                if not lst[extif] then
                    lst[extif]  = true

                    local sinfo = _ICInfo[extif]
                    genSuperOrderList(sinfo, lst, super)
                    if super and (sinfo[FLD_IC_SUPFTR] or sinfo[FLD_IC_SUPMTD]) then super[extif] = sinfo end
                    tinsert(lst, extif)
                end
            end
        end

        return lst, super
    end

    local genCacheOnPriority    = function (source, target, objpri, inhrtp, super, ismeta, featuretarget, objfeature, stack)
        for k, v in pairs, source do
            if v and not (ismeta and META_KEYS[k] == nil) and not (featuretarget and getobjectvalue(v, "IsStatic", true)) then
                local priority  = inhrtp and inhrtp[k] or INRT_PRIORITY_NORMAL
                if priority >= (objpri[k] or INRT_PRIORITY_ABSTRACT) then
                    if super and target[k] and (objpri[k] or INRT_PRIORITY_NORMAL) > INRT_PRIORITY_ABSTRACT then
                        -- abstract can't be used as Super
                        if ismeta and META_KEYS[k] ~= k then
                            super[k] = target[META_KEYS[k]]
                        else
                            super[k] = target[k]
                        end
                    end

                    objpri[k]   = priority

                    if featuretarget then
                        if getobjectvalue(v, "IsShareable", true) and objfeature and objfeature[k] then
                            target[k]   = objfeature[k]
                        else
                            v           = getobjectvalue(v, "GetAccessor", true, featuretarget) or v
                            if type(safeget(v, "Get")) ~= "function" or type(safeget(v, "Set")) ~= "function" then
                                error(strformat("the feature named %q is not valid", k), stack + 1)
                            end
                            target[k]   = v
                        end
                    else
                        target[k]       = v
                        if ismeta then
                            local mk    = META_KEYS[k]
                            if mk ~= k then
                                target[mk]  = source[mk]
                            end
                        end
                    end
                end
            end
        end
    end

    local reOrderExtendIF       = function (info, super)
        -- Re-generate the interface order list
        local lstIF         = genSuperOrderList(info, _Cache(), super)
        local idxIF         = FLD_IC_STEXT + #lstIF

        for i, extif in ipairs, lstIF, 0 do
            info[idxIF - i] = extif
        end
        _Cache(lstIF)

        return super
    end

    local getInitICInfo         = function (target, isclass)
        local info              = _ICInfo[target]

        local ninfo             = {
            -- STATIC FIELDS
            [FLD_IC_SUPCLS]     = info and info[FLD_IC_SUPCLS],
            [FLD_IC_MOD]        = info and info[FLD_IC_MOD] or isclass and MOD_INITVAL_CLS or MOD_INITVAL_IF,
            [FLD_IC_CTOR]       = info and info[FLD_IC_CTOR],
            [FLD_IC_DTOR]       = info and info[FLD_IC_DTOR],
            [FLD_IC_FIELD]      = info and info[FLD_IC_FIELD] and tblclone(info[FLD_IC_FIELD], {}),
            [FLD_IC_EXIST]      = info and info[FLD_IC_EXIST],
            [FLD_IC_NEWOBJ]     = info and info[FLD_IC_NEWOBJ],
            [FLD_IC_TYPMTD]     = info and info[FLD_IC_TYPMTD] and tblclone(info[FLD_IC_TYPMTD], {}) or false,
            [FLD_IC_TYPMTM]     = info and info[FLD_IC_TYPMTM] and tblclone(info[FLD_IC_TYPMTM], {}),
            [FLD_IC_TYPFTR]     = info and info[FLD_IC_TYPFTR] and tblclone(info[FLD_IC_TYPFTR], {}),
            [FLD_IC_INHRTP]     = info and info[FLD_IC_INHRTP] and tblclone(info[FLD_IC_INHRTP], {}),
            [FLD_IC_REQCLS]     = info and info[FLD_IC_REQCLS],
            [FLD_IC_SUPER]      = info and info[FLD_IC_SUPER],
            [FLD_IC_THIS]       = info and info[FLD_IC_THIS],
            [FLD_IC_ANYMSCL]    = info and info[FLD_IC_ANYMSCL] or isclass and nil,
            [FLD_IC_DEBUGSR]    = info and info[FLD_IC_DEBUGSR] or isclass and INI_FLD_DEBUGSR or nil,

            -- CACHE FIELDS
            [FLD_IC_STAFTR]     = info and info[FLD_IC_STAFTR] and tblclone(info[FLD_IC_STAFTR], {}),
            [FLD_IC_OBJFTR]     = info and info[FLD_IC_OBJFTR] and tblclone(info[FLD_IC_OBJFTR], {}),
        }

        if info then for i, extif in ipairs, info, FLD_IC_STEXT - 1 do ninfo[i] = extif end end

        return ninfo
    end

    local genMetaIndex          = function (info)
        local token = 0
        local upval = _Cache()
        local meta  = info[FLD_IC_OBJMTM]

        if info[FLD_IC_SUPINFO] and not validateFlags(MOD_NOSUPER_OBJ, info[FLD_IC_MOD]) then
            token   = turnOnFlags(FLG_IC_SUPACC, token)
            tinsert(upval, info[FLD_IC_SUPINFO])
        end

        if info[FLD_IC_OBJMTD] then
            token   = turnOnFlags(FLG_IC_OBJMTD, token)
            tinsert(upval, info[FLD_IC_OBJMTD])
        end

        if info[FLD_IC_OBJFTR] then
            token   = turnOnFlags(FLG_IC_OBJFTR, token)
            tinsert(upval, info[FLD_IC_OBJFTR])
        end

        local data  = info[FLD_IC_TYPMTM] and info[FLD_IC_TYPMTM][IC_META_INDEX] or meta[META_KEYS[IC_META_INDEX]]
        if data then
            if type(data) == "function" then
                token = turnOnFlags(FLG_IC_IDXFUN, token)
            else
                token = turnOnFlags(FLG_IC_IDXTBL, token)
            end
            tinsert(upval, data)
        end

        if validateFlags(MOD_NONILVAL_OBJ, info[FLD_IC_MOD]) then
            token   = turnOnFlags(FLG_IC_NNILVL, token)
        end

        -- No __index generated
        if token == 0                                       then meta[IC_META_INDEX] = fakefunc             return _Cache(upval) end
        -- Use the object method cache directly
        if token == FLG_IC_OBJMTD                           then meta[IC_META_INDEX] = info[FLD_IC_OBJMTD]  return _Cache(upval) end
        -- Use the custom __index directly
        if token == FLG_IC_IDXFUN or token == FLG_IC_IDXTBL then meta[IC_META_INDEX] = data                 return _Cache(upval) end

        if not _ICIndexMap[token] then
            local head      = _Cache()
            local body      = _Cache()
            local apis      = _Cache()

            tinsert(body, "")                       -- remain for shareable variables
            tinsert(body, "return function(%s)")    -- remain for special variables
            tinsert(body, [[return function(self, key)]])

            if validateFlags(FLG_IC_SUPACC, token) then
                uinsert(apis, "rawget")
                uinsert(apis, "error")
                uinsert(apis, "strformat")
                uinsert(apis, "tostring")
                tinsert(head, "spinfo")
                tinsert(body, [[
                    local sp = rawget(self, "]] .. OBJ_SUPER_ACCESS .. [[")
                    if sp then
                        self["]] .. OBJ_SUPER_ACCESS .. [["] = nil
                        local sinfo = spinfo[sp]
                        if sinfo then
                            local mtd = sinfo[]] .. FLD_IC_SUPMTD .. [[]
                            mtd = mtd and mtd[key]
                            if mtd then return mtd end

                            local ftr = sinfo[]] .. FLD_IC_SUPFTR .. [[]
                            ftr = ftr and ftr[key]
                            if ftr then return ftr:Get(self) end
                        end

                        error(strformat("No super method or feature named %q can be found", tostring(key)), 2)
                    end
                ]])
            end

            if validateFlags(FLG_IC_OBJMTD, token) then
                tinsert(head, "methods")
                tinsert(body, [[
                    local mtd = methods[key]
                    if mtd then return mtd end
                ]])
            end

            if validateFlags(FLG_IC_OBJFTR, token) then
                tinsert(head, "features")
                tinsert(body, [[
                    local ftr = features[key]
                    if ftr then return ftr:Get(self) end
                ]])
            end

            if validateFlags(FLG_IC_IDXFUN, token) then
                tinsert(head, "_index")
                if validateFlags(FLG_IC_NNILVL, token) then
                    tinsert(body, [[
                        local val = _index(self, key)
                        if val ~= nil then return val end
                    ]])
                else
                    tinsert(body, [[return _index(self, key)]])
                end
            elseif validateFlags(FLG_IC_IDXTBL, token) then
                tinsert(head, "_index")
                if validateFlags(FLG_IC_NNILVL, token) then
                    tinsert(body, [[
                        local val = _index[key]
                        if val ~= nil then return val end
                    ]])
                else
                    tinsert(body, [[return _index[key] ]])
                end
            end

            if validateFlags(FLG_IC_NNILVL, token) then
                uinsert(apis, "error")
                uinsert(apis, "strformat")
                uinsert(apis, "tostring")
                tinsert(body, [[error(strformat("The object don't have any field that named %q", tostring(key)), 2)]])
            end

            tinsert(body, [[end]])
            tinsert(body, [[end]])

            if #apis > 0 then
                local declare   = tblconcat(apis, ", ")
                body[1]         = strformat("local %s = %s", declare, declare)
            end

            body[2]             = strformat(body[2], #head > 0 and tblconcat(head, ", ") or "")

            _ICIndexMap[token] = loadSnippet(tblconcat(body, "\n"), "Class_Index_" .. token)()

            if #head == 0 then
                _ICIndexMap[token] = _ICIndexMap[token]()
            end

            _Cache(head)
            _Cache(body)
            _Cache(apis)
        end

        if #upval > 0 then
            meta[IC_META_INDEX] = _ICIndexMap[token](unpack(upval))
        else
            meta[IC_META_INDEX] = _ICIndexMap[token]
        end

        _Cache(upval)
    end

    local genMetaNewIndex       = function (info)
        local token = 0
        local upval = _Cache()
        local meta  = info[FLD_IC_OBJMTM]

        if info[FLD_IC_SUPINFO] and not validateFlags(MOD_NOSUPER_OBJ, info[FLD_IC_MOD]) then
            token   = turnOnFlags(FLG_IC_SUPACC, token)
            tinsert(upval, info[FLD_IC_SUPINFO])
        end

        if info[FLD_IC_OBJFTR] and next(info[FLD_IC_OBJFTR]) then
            token   = turnOnFlags(FLG_IC_OBJFTR, token)
            tinsert(upval, info[FLD_IC_OBJFTR])
        end

        if validateFlags(MOD_ATTRFUNC_OBJ, info[FLD_IC_MOD]) then
            token   = turnOnFlags(FLG_IC_OBJATR, token)
        end

        local data  = meta[META_KEYS[IC_META_NEWIDX]]

        if data then
            token   = turnOnFlags(FLG_IC_NEWIDX, token)
            tinsert(upval, data)
        elseif validateFlags(MOD_NORAWSET_OBJ, info[FLD_IC_MOD]) then
            token   = turnOnFlags(FLG_IC_NRAWST, token)
        end

        -- No __newindex generated
        if token == 0               then meta[IC_META_NEWIDX] = nil  return _Cache(upval) end
        -- Use the custom __newindex directly
        if token == FLG_IC_NEWIDX   then meta[IC_META_NEWIDX] = data return _Cache(upval) end

        if not _ICNewIdxMap[token] then
            local head      = _Cache()
            local body      = _Cache()
            local apis      = _Cache()

            tinsert(body, "")                       -- remain for shareable variables
            tinsert(body, "return function(%s)")    -- remain for special variables
            tinsert(body, [[return function(self, key, value)]])

            if validateFlags(FLG_IC_SUPACC, token) then
                uinsert(apis, "rawget")
                uinsert(apis, "error")
                uinsert(apis, "strformat")
                uinsert(apis, "tostring")
                tinsert(head, "spinfo")
                tinsert(body, [[
                    local sp = rawget(self, "]] .. OBJ_SUPER_ACCESS .. [[")
                    if sp then
                        self["]] .. OBJ_SUPER_ACCESS .. [["] = nil
                        local sinfo = spinfo[sp]
                        if sinfo then
                            local ftr = sinfo[]] .. FLD_IC_SUPFTR .. [[]
                            ftr = ftr and ftr[key]
                            if ftr then ftr:Set(self, value, 2) return end
                        end

                        error(strformat("No super feature named %q can be found", tostring(key)), 2)
                    end
                ]])
            end

            if validateFlags(FLG_IC_OBJFTR, token) then
                tinsert(head, "feature")
                tinsert(body, [[
                    local ftr = feature[key]
                    if ftr then ftr:Set(self, value, 2) return end
                ]])
            end

            if validateFlags(FLG_IC_NEWIDX, token) or not validateFlags(FLG_IC_NRAWST, token) then
                if validateFlags(FLG_IC_OBJATR, token) then
                    uinsert(apis, "type")
                    uinsert(apis, "attribute")
                    uinsert(apis, "ATTRTAR_FUNCTION")
                    tinsert(body, [[
                        local tvalue = type(value)
                        if tvalue == "function" and attribute.HaveRegisteredAttributes() then
                            attribute.SaveAttributes(value, ATTRTAR_FUNCTION, 2)
                            local ret = attribute.InitDefinition(value, ATTRTAR_FUNCTION, value, self, key, 2)
                            if value ~= ret then
                                attribute.ToggleTarget(value, ret)
                                value = ret
                            end
                            attribute.ApplyAttributes (value, ATTRTAR_FUNCTION, self, key, 2)
                            attribute.AttachAttributes(value, ATTRTAR_FUNCTION, self, key, 2)
                        end
                    ]])
                end

                if validateFlags(FLG_IC_NEWIDX, token) then
                    tinsert(head, "_newindex")
                    tinsert(body, [[_newindex(self, key, value)]])
                else
                    uinsert(apis, "rawset")
                    tinsert(body, [[rawset(self, key, value)]])
                end
            end

            if validateFlags(FLG_IC_NRAWST, token) then
                uinsert(apis, "error")
                uinsert(apis, "strformat")
                uinsert(apis, "tostring")
                tinsert(body, [[error(strformat("The object can't accept field that named %q", tostring(key)), 2)]])
            end

            tinsert(body, [[end]])
            tinsert(body, [[end]])

            if #apis > 0 then
                local declare   = tblconcat(apis, ", ")
                body[1]         = strformat("local %s = %s", declare, declare)
            end

            body[2]             = strformat(body[2], #head > 0 and tblconcat(head, ", ") or "")

            _ICNewIdxMap[token] = loadSnippet(tblconcat(body, "\n"), "Class_NewIndex_" .. token)()

            if #head == 0 then
                _ICNewIdxMap[token] = _ICNewIdxMap[token]()
            end

            _Cache(head)
            _Cache(body)
            _Cache(apis)
        end

        if #upval > 0 then
            meta[IC_META_NEWIDX]= _ICNewIdxMap[token](unpack(upval))
        else
            meta[IC_META_NEWIDX]= _ICNewIdxMap[token]
        end

        _Cache(upval)
    end

    local genConstructor        = function (target, info)
        if validateFlags(MOD_ABSTRACT_CLS, info[FLD_IC_MOD]) then
            local msg = strformat("The %s is abstract, can't be used to create objects", tostring(target))
            info[FLD_IC_OBCTOR] = function() error(msg, 3) end
            return
        end

        local token = 0
        local upval = _Cache()

        tinsert(upval, info[FLD_IC_OBJMTM])

        if info[FLD_IC_OBJEXT] then
            token   = turnOnFlags(FLG_IC_EXIST, token)
            tinsert(upval, info[FLD_IC_OBJEXT])
        end

        if info[FLD_IC_OBJNEW] then
            token   = turnOnFlags(FLG_IC_NEWOBJ, token)
            tinsert(upval, info[FLD_IC_OBJNEW])
        end

        if info[FLD_IC_FIELD] then
            token   = turnOnFlags(FLG_IC_FIELD, token)
            tinsert(upval, info[FLD_IC_FIELD])
        end

        if info[FLD_IC_CLINIT] then
            token   = turnOnFlags(FLG_IC_HSCLIN, token)
            tinsert(upval, info[FLD_IC_CLINIT])
        end

        if info[FLD_IC_STINIT] then
            token   = turnOnFlags(FLG_IC_HSIFIN, token)
            local i = FLD_IC_STINIT
            while info[i + 1] do i = i + 1 end
            tinsert(upval, i)
        end

        if not _ClassCtorMap[token] then
            local head      = _Cache()
            local body      = _Cache()
            local apis      = _Cache()
            local hasctor   = validateFlags(FLG_IC_HSCLIN, token)

            uinsert(apis, "setmetatable")

            tinsert(head, "objmeta")

            tinsert(body, "")                       -- remain for shareable variables
            tinsert(body, "return function(%s)")    -- remain for special variables
            if hasctor then
                tinsert(body, [[return function(info, ...)]])
            else
                tinsert(body, [[return function(info, first, ...)]])
            end

            tinsert(body, [[local obj]])

            if validateFlags(FLG_IC_EXIST, token) then
                tinsert(head, "extobj")
                if hasctor then
                    tinsert(body, [[obj = extobj(...) if obj ~= nil then return obj end]])
                else
                    tinsert(body, [[obj = extobj(first, ...) if obj ~= nil then return obj end]])
                end
            end

            if validateFlags(FLG_IC_NEWOBJ, token) then
                uinsert(apis, "type")
                tinsert(head, "newobj")
                tinsert(body, [[local cutargs]])
                if hasctor then
                    tinsert(body, [[obj, cutargs = newobj(...)]])
                else
                    tinsert(body, [[obj, cutargs = newobj(first, ...)]])
                end
                tinsert(body, [[if type(obj) ~= "table" then obj, cutargs = nil, false end]])
            end

            if not hasctor then
                uinsert(apis, "select")
                uinsert(apis, "type")
                uinsert(apis, "getmetatable")

                if validateFlags(FLG_IC_NEWOBJ, token) then
                    tinsert(body, [[local init = not cutargs and select("#", ...) == 0 and type(first) == "table" and getmetatable(first) == nil and first or nil]])
                else
                    tinsert(body, [[local init = select("#", ...) == 0 and type(first) == "table" and getmetatable(first) == nil and first or nil]])
                end
            end

            if validateFlags(FLG_IC_NEWOBJ, token) then
                tinsert(body, [[obj = obj or {}]])
            else
                tinsert(body, [[obj = {}]])
            end

            if validateFlags(FLG_IC_FIELD, token) then
                uinsert(apis, "pairs")
                tinsert(head, "fields")
                tinsert(body, [[for fld, val in pairs, fields do if obj[fld] == nil then obj[fld] = val end end]])
            end

            if validateFlags(FLG_IC_NEWOBJ, token) then
                uinsert(apis, "pcall")
                uinsert(apis, "strformat")
                uinsert(apis, "tostring")
                uinsert(apis, "throw")
                tinsert(body, [[if not pcall(setmetatable, obj, objmeta) then throw(strformat("The %s's __new meta-method doesn't provide a valid table as object", tostring(objmeta["__metatable"]))) end]])
            else
                tinsert(body, [[setmetatable(obj, objmeta)]])
            end

            if hasctor then
                tinsert(head, "clinit")
                if validateFlags(FLG_IC_NEWOBJ, token) then
                    tinsert(body, [[if cutargs then clinit(obj) else clinit(obj, ...) end]])
                else
                    tinsert(body, [[clinit(obj, ...)]])
                end
            else
                uinsert(apis, "pcall")
                uinsert(apis, "loadInitTable")
                uinsert(apis, "strmatch")
                uinsert(apis, "throw")
                tinsert(body, [[if init then local ok, msg = pcall(loadInitTable, obj, init) if not ok then throw(strmatch(msg, "%d+:%s*(.-)$") or msg) end end]])
            end

            if validateFlags(FLG_IC_HSIFIN, token) then
                tinsert(head, "_max")

                tinsert(body, [[for i = ]] .. FLD_IC_STINIT .. [[, _max do info[i](obj) end]])
            end

            tinsert(body, [[return obj end end]])

            if #apis > 0 then
                local declare   = tblconcat(apis, ", ")
                body[1]         = strformat("local %s = %s", declare, declare)
            end

            body[2]             = strformat(body[2], #head > 0 and tblconcat(head, ", ") or "")

            _ClassCtorMap[token] = loadSnippet(tblconcat(body, "\n"), "Class_Ctor_" .. token)()

            if #head == 0 then
                _ClassCtorMap[token] = _ClassCtorMap[token]()
            end

            _Cache(head)
            _Cache(body)
            _Cache(apis)
        end

        if #upval > 0 then
            info[FLD_IC_OBCTOR] = _ClassCtorMap[token](unpack(upval))
        else
            info[FLD_IC_OBCTOR] = _ClassCtorMap[token]
        end

        _Cache(upval)
    end

    local genTypeCaches         = function (target, info, stack)
        local isclass   = class.Validate(target)
        local realCls   = isclass and not class.IsAbstract(target)
        local objpri    = _Cache()
        local objmeta   = _Cache()
        local objftr    = _Cache()
        local objmtd    = _Cache()
        local objfld    = realCls and _Cache()

        -- Re-generate the extended interfaces order list
        local spcache   = reOrderExtendIF(info, realCls and _Cache())

        stack           = stack + 1

        -- The init & dispose link for extended interfaces & super classes
        local initIdx   = FLD_IC_STINIT
        local dispIdx   = FLD_IC_ENDISP
        local supctor, supext, supnew

        -- Save super class's dtor & ctor
        for _, sinfo, isextIF in iterSuperInfo(info, true) do
            if not isextIF then
                if sinfo[FLD_IC_CTOR] then
                    supctor         = sinfo[FLD_IC_CTOR]
                end

                if sinfo[FLD_IC_EXIST] then
                    supext          = sinfo[FLD_IC_EXIST]
                end

                if sinfo[FLD_IC_NEWOBJ] then
                    supnew          = sinfo[FLD_IC_NEWOBJ]
                end

                if sinfo[FLD_IC_DTOR] then
                    info[dispIdx]   = sinfo[FLD_IC_DTOR]
                    dispIdx         = dispIdx - 1
                end
            end
        end

        -- Save class's dtor
        if info[FLD_IC_DTOR] then
            info[dispIdx]   = info[FLD_IC_DTOR]
            dispIdx         = dispIdx - 1
        end

        -- Save super to caches
        for _, sinfo, isextIF in iterSuperInfo(info, true) do
            local inhrtp    = sinfo[FLD_IC_INHRTP]

            if sinfo[FLD_IC_TYPMTD] then
                genCacheOnPriority(sinfo[FLD_IC_TYPMTD], objmtd, objpri, inhrtp, nil, nil, nil, nil, stack)
            end

            if sinfo[FLD_IC_TYPMTM] then
                genCacheOnPriority(sinfo[FLD_IC_TYPMTM], objmeta, objpri, inhrtp, nil, true, nil, nil, stack)
            end

            if sinfo[FLD_IC_TYPFTR] then
                genCacheOnPriority(sinfo[FLD_IC_TYPFTR], objftr, objpri, inhrtp, nil, false, target, sinfo[FLD_IC_OBJFTR], stack)
            end

            if realCls then
                -- Save fields
                if sinfo[FLD_IC_FIELD] then
                    tblclone(sinfo[FLD_IC_FIELD], objfld, false, true)
                end

                if isextIF then
                    -- Save ctor
                    if sinfo[FLD_IC_CTOR] then
                        info[initIdx]   = sinfo[FLD_IC_CTOR]
                        initIdx         = initIdx + 1
                    end

                    -- Save dtor
                    if sinfo[FLD_IC_DTOR] then
                        info[dispIdx]       = sinfo[FLD_IC_DTOR]
                        dispIdx             = dispIdx - 1
                    end
                end
            end
        end

        -- Save self to caches
        local inhrtp    = info[FLD_IC_INHRTP]
        local super     = _Cache()

        if info[FLD_IC_TYPMTD] then
            genCacheOnPriority(info[FLD_IC_TYPMTD], objmtd, objpri, inhrtp, super, nil, nil, nil, stack)
        end

        if info[FLD_IC_TYPMTM] then
            genCacheOnPriority(info[FLD_IC_TYPMTM], objmeta, objpri, inhrtp, super, true, nil, nil, stack)
        end

        if next(super) then info[FLD_IC_SUPMTD] = super else _Cache(super) end

        if info[FLD_IC_TYPFTR] then
            super       = _Cache()
            genCacheOnPriority(info[FLD_IC_TYPFTR], objftr, objpri, inhrtp, super, false, target, info[FLD_IC_OBJFTR], stack)
            if next(super) then info[FLD_IC_SUPFTR] = super else _Cache(super) end

            -- Check static features
            local staftr= info[FLD_IC_STAFTR]

            for name, ftr in pairs, info[FLD_IC_TYPFTR] do
                if getobjectvalue(ftr, "IsStatic", true) then
                    if not (staftr and staftr[name] and getobjectvalue(ftr, "IsShareable", true)) then
                        staftr      = staftr or {}

                        ftr         = getobjectvalue(ftr, "GetAccessor", true, target) or ftr
                        if type(safeget(ftr, "Get")) ~= "function" or type(safeget(ftr, "Set")) ~= "function" then
                            error(strformat("the feature named %q is not valid", k), stack + 1)
                        end
                        staftr[name]= ftr
                    end
                end
            end
            info[FLD_IC_STAFTR]     = staftr
        end

        if realCls and info[FLD_IC_FIELD] then
            tblclone(info[FLD_IC_FIELD], objfld, false, true)
        end

        -- Generate super if needed, include the interface
        if not info[FLD_IC_SUPER] and (info[FLD_IC_SUPFTR] or info[FLD_IC_SUPMTD] or
            (isclass and info[FLD_IC_CTOR] and info[FLD_IC_SUPCLS] and (_ICInfo[info[FLD_IC_SUPCLS]][FLD_IC_CTOR] or _ICInfo[info[FLD_IC_SUPCLS]][FLD_IC_CLINIT]))) then
            info[FLD_IC_SUPER] = prototype.NewProxy(isclass and tsuperclass or tsuperinterface)
            saveSuperMap(info[FLD_IC_SUPER], target)
        end

        -- Save caches to fields
        if not isclass then
            -- Check one abstract method
            local absmtd
            for k, v in pairs, objmtd do
                if objpri[k] == INRT_PRIORITY_ABSTRACT then
                    if absmtd == nil then
                        absmtd  = k
                    else
                        absmtd  = false
                        break
                    end
                end
            end
            info[FLD_IC_ONEABS] = absmtd or nil

            _Cache(objpri)
            _Cache(objmeta)
            _Cache(objmtd)
            if not next(objftr) then _Cache(objftr) objftr = nil end

            info[FLD_IC_OBJFTR] = objftr

            -- Gen anonymous class
            if validateFlags(MOD_ANYMOUS_CLS, info[FLD_IC_MOD]) and not info[FLD_IC_ANYMSCL] then
                local aycls     = prototype.NewProxy(tclass)
                local ainfo     = getInitICInfo(aycls, true)

                ainfo[FLD_IC_MOD]   = turnOnFlags(MOD_SEALED_IC, ainfo[FLD_IC_MOD])
                ainfo[FLD_IC_STEXT] = target

                -- Register the _ICDependsMap
                _ICDependsMap[target] = _ICDependsMap[target] or {}
                tinsert(_ICDependsMap[target], aycls)

                -- Save the anonymous class
                saveICInfo(aycls, ainfo)

                info[FLD_IC_ANYMSCL] = aycls
            end
        else
            if not info[FLD_IC_THIS] and info[FLD_IC_CTOR] then
                info[FLD_IC_THIS] = prototype.NewProxy(tthisclass)
                saveThisMap(info[FLD_IC_THIS], target)
            end

            if not realCls then
                _Cache(objpri)
                _Cache(objmeta)
                _Cache(objmtd)
                if not next(objftr) then _Cache(objftr) objftr = nil end

                info[FLD_IC_CLINIT]     = nil
                info[FLD_IC_OBJMTM]     = nil
                info[FLD_IC_OBJFTR]     = objftr
                info[FLD_IC_OBJMTD]     = nil
                info[FLD_IC_OBJFLD]     = nil
            else
                -- Set object's prototype
                objmeta[IC_META_TABLE]  = target

                -- Auto-gen dispose for object methods
                local FLD_IC_STDISP     = dispIdx + 1
                if FLD_IC_STDISP <= FLD_IC_ENDISP then
                    objmtd[IC_META_DISPOB]  = function(self)
                        for i = FLD_IC_STDISP, FLD_IC_ENDISP do info[i](self) end
                        rawset(wipe(self), IC_META_DISPOB, true)
                    end
                end

                -- Save self super info
                if info[FLD_IC_SUPER] then
                    spcache[target]     = info
                end

                _Cache(objpri)
                if not next(objmtd) then _Cache(objmtd) objmtd = nil end
                if not next(objfld) then _Cache(objfld) objfld = nil end
                if not next(objftr) then _Cache(objftr) objftr = nil end
                if not next(spcache)then _Cache(spcache)spcache= nil end

                info[FLD_IC_SUPINFO]    = spcache
                info[FLD_IC_CLINIT]     = info[FLD_IC_CTOR] or supctor
                info[FLD_IC_OBJMTM]     = objmeta
                info[FLD_IC_OBJFTR]     = objftr
                info[FLD_IC_OBJMTD]     = objmtd or false
                info[FLD_IC_OBJFLD]     = objfld
                info[FLD_IC_OBJEXT]     = info[FLD_IC_EXIST] or supext
                info[FLD_IC_OBJNEW]     = info[FLD_IC_NEWOBJ] or supnew

                genMetaIndex(info)
                genMetaNewIndex(info)

                -- Copy the metatable if the class is single version
                if class.IsSingleVersion(target) then
                    local oinfo     = _ICInfo[target]

                    if oinfo and oinfo[FLD_IC_OBJMTM] then
                        info[FLD_IC_OBJMTM] = tblclone(objmeta, oinfo[FLD_IC_OBJMTM], false, true)
                    end
                end
            end
            genConstructor(target, info)
        end
    end

    local reDefineChildren      = function (target, stack)
        if _ICDependsMap[target] then
            for _, child in ipairs, _ICDependsMap[target], 0 do
                if not _ICBuilderInfo[child] then  -- Not in definition mode
                    if interface.Validate(child) then
                        interface.RefreshDefinition(child, stack + 1)
                    else
                        class.RefreshDefinition(child, stack + 1)
                    end
                end
            end
        end
    end

    local saveObjectMethod
        saveObjectMethod        = function (target, name, func, child)
        local info, def         = getICTargetInfo(target)

        if def then return end

        if child and info[FLD_IC_TYPMTD] and info[FLD_IC_TYPMTD][name] ~= nil and (info[FLD_IC_TYPMTD][name] == false or not (info[FLD_IC_INHRTP] and info[FLD_IC_INHRTP][name] == INRT_PRIORITY_ABSTRACT)) then return end

        if info[FLD_IC_OBJMTD] ~= nil then
            info[FLD_IC_OBJMTD] = saveStorage(info[FLD_IC_OBJMTD] or {}, name, func)
            genMetaIndex(info)
        end

        if _ICDependsMap[target] then
            for _, child in ipairs, _ICDependsMap[target], 0 do
                saveObjectMethod(child, name, func, true)
            end
        end
    end

    -- Shared APIS
    local preDefineCheck        = function (target, name, stack, allowDefined)
        local info, def         = getICTargetInfo(target)
        stack                   = parsestack(stack)
        if not info then return nil, nil, stack, "the target is not valid" end
        if not allowDefined and not def then return nil, nil, stack, strformat("the %s's definition is finished", tostring(target)) end
        if not name or type(name) ~= "string" then return info, nil, stack, "the name must be a string." end
        name                    = strtrim(name)
        if name == "" then return info, nil, stack, "the name can't be empty." end
        return info, name, stack, nil, def
    end

    local addSuperType          = function (info, target, supType)
        local isIF              = interface.Validate(supType)

        -- Clear _ICDependsMap for old extend interfaces
        for i = #info, FLD_IC_STEXT, -1 do
            local extif = info[i]

            if interface.IsSubType(supType, extif) then
                for k, v in ipairs, _ICDependsMap[extif], 0 do
                    if v == target then tremove(_ICDependsMap[extif], k) break end
                end
            end

            if isIF then info[i + 1] = extif end
        end

        if isIF then
            info[FLD_IC_STEXT]  = supType
        else
            info[FLD_IC_SUPCLS] = supType
        end

        -- Register the _ICDependsMap
        _ICDependsMap[supType]  = _ICDependsMap[supType] or {}
        tinsert(_ICDependsMap[supType], target)

        -- Re-generate the interface order list
        reOrderExtendIF(info)
    end

    local addExtend             = function (target, extendIF, stack)
        local info, _, stack, msg  = preDefineCheck(target, nil, stack)

        if not info then return msg, stack end
        if not interface.Validate(extendIF) then return "the extendinterface must be an interface", stack end
        if interface.IsFinal(extendIF) then return strformat("the %s is marked as final, can't be extended", tostring(extendIF)), stack end

        -- Check if already extended
        if interface.IsSubType(target, extendIF) then return end

        -- Check the extend interface's require class
        local reqcls = interface.GetRequireClass(extendIF)

        if class.Validate(target) then
            if reqcls and not class.IsSubType(target, reqcls) then
                return strformat("the class must be %s's sub-class", tostring(reqcls)), stack
            end
        elseif interface.IsSubType(extendIF, target) then
            return "the extendinterface is a sub type of the interface", stack
        elseif reqcls then
            local rcls = interface.GetRequireClass(target)

            if rcls then
                if class.IsSubType(reqcls, rcls) then
                    interface.SetRequireClass(target, reqcls, stack + 2)
                elseif not class.IsSubType(rcls, reqcls) then
                    return strformat("the interface's require class must be %s's sub-class", tostring(reqcls)), stack
                end
            else
                interface.SetRequireClass(target, reqcls, stack + 2)
            end
        end

        -- Add the extend interface
        addSuperType(info, target, extendIF)
    end

    local addMethod             = function (target, name, func, stack)
        local info, name, stack, msg, def = preDefineCheck(target, name, stack, true)

        if msg then return msg, stack end

        if META_KEYS[name] ~= nil then return strformat("the %s can't be used as method name", name), stack end
        if type(func) ~= "function" then return "the func must be a function", stack end

        local typmtd = info[FLD_IC_TYPMTD]
        if not def and (typmtd and typmtd[name] ~= nil and (typmtd[name] == false or validateFlags(MOD_SEALED_IC, info[FLD_IC_MOD]))
            or info[FLD_IC_TYPFTR] and info[FLD_IC_TYPFTR][name] ~= nil) then
            return strformat("The %s can't be overridden", name), stack
        end

        stack       = stack + 2

        attribute.SaveAttributes(func, ATTRTAR_METHOD, stack)

        if not (typmtd and typmtd[name] == false) then
            attribute.InheritAttributes(func, ATTRTAR_METHOD, getSuperMethod(info, name))
        end

        local ret = attribute.InitDefinition(func, ATTRTAR_METHOD, func, target, name, stack)
        if ret ~= func then attribute.ToggleTarget(func, ret) func = ret end

        attribute.ApplyAttributes (func, ATTRTAR_METHOD, target, name, stack)
        attribute.AttachAttributes(func, ATTRTAR_METHOD, target, name, stack)

        if def then
            if typmtd and typmtd[name] == false then
                info[name] = func
            else
                info[FLD_IC_TYPMTD] = typmtd or _Cache()
                info[FLD_IC_TYPMTD][name] = func
            end
        else
            info[FLD_IC_TYPMTD]     = saveStorage(typmtd or _Cache(), name, func)
            return saveObjectMethod(target, name, func)
        end
    end

    local addMetaData           = function (target, name, data, stack)
        local info, name, stack, msg = preDefineCheck(target, name, stack)

        if msg then return msg, stack end

        if not META_KEYS[name] then return "the name is not valid", stack end

        local tdata = type(data)

        if name == IC_META_FIELD then
            if tdata ~= "table" then return "the data must be a table", stack end
        elseif name == IC_META_INDEX then
            if tdata ~= "function" and tdata ~= "table" then return "the data must be a function or table", stack end
        elseif tdata ~= "function" then
            return "the data must be a function", stack
        end

        stack       = stack + 2

        if tdata == "function" then
            attribute.SaveAttributes(data, ATTRTAR_METHOD, stack)

            attribute.InheritAttributes(data, ATTRTAR_METHOD, getSuperMetaMethod(info, name))

            local ret = attribute.InitDefinition(data, ATTRTAR_METHOD, data, target, name, stack)
            if ret ~= data then attribute.ToggleTarget(data, ret) data = ret end

            attribute.ApplyAttributes (data, ATTRTAR_METHOD, target, name, stack)
            attribute.AttachAttributes(data, ATTRTAR_METHOD, target, name, stack)
        end

        -- Save
        local metaFld = META_KEYS[name]

        if type(metaFld) == "string" then
            info[FLD_IC_TYPMTM]         = info[FLD_IC_TYPMTM] or {}
            info[FLD_IC_TYPMTM][name]   = data

            if metaFld ~= name then
                info[FLD_IC_TYPMTM][metaFld] = tdata == "table" and function(_, k) return data[k] end or data
            end
        else
            info[metaFld]       = data
        end
    end

    local addFeature            = function (target, name, ftr, stack)
        local info, name, stack, msg = preDefineCheck(target, name, stack)

        if msg then return msg, stack end
        if META_KEYS[name] ~= nil then return strformat("the %s can't be used as feature name", name), stack end

        info[FLD_IC_TYPFTR]         = info[FLD_IC_TYPFTR] or _Cache()
        info[FLD_IC_TYPFTR][name]   = ftr

        if info[FLD_IC_STAFTR] and info[FLD_IC_STAFTR][name] then
            info[FLD_IC_STAFTR][name] = nil
        elseif info[FLD_IC_OBJFTR] and info[FLD_IC_OBJFTR][name] then
            info[FLD_IC_OBJFTR][name] = nil
        end
    end

    local addFields             = function (target, fields, stack)
        local info, name, stack, msg = preDefineCheck(target, nil, stack)
        if not info then return msg, stack end
        if type(fields) ~= "table" then return "the fields must be a table", stack end

        info[FLD_IC_FIELD]      = tblclone(fields, info[FLD_IC_FIELD] or _Cache(), true, true)
    end

    local setRequireClass       = function (target, cls, stack)
        local info, _, stack, msg  = preDefineCheck(target, nil, stack)

        if not info then return msg, stack end

        if not interface.Validate(target) then return "the target is not valid", stack end
        if not class.Validate(cls) then return "the requireclass must be a class", stack end
        if info[FLD_IC_REQCLS] and not class.IsSubType(cls, info[FLD_IC_REQCLS]) then return strformat("The requireclass must be %s's sub-class", tostring(info[FLD_IC_REQCLS])), stack end

        info[FLD_IC_REQCLS] = cls
    end

    local setSuperClass         = function (target, super, stack)
        local info, _, stack, msg  = preDefineCheck(target, nil, stack)

        if not info then return msg, stack end

        if not class.Validate(target) then return "the target is not valid", stack end
        if not class.Validate(super) then return "the superclass must be a class", stack end

        if info[FLD_IC_SUPCLS] and info[FLD_IC_SUPCLS] ~= super then return strformat("The %s already has a super class", tostring(target)), stack end

        if info[FLD_IC_SUPCLS] then return end

        addSuperType(info, target, super)
    end

    local setObjectSourceDebug  = function (target, stack)
        local info, _, stack, msg  = preDefineCheck(target, nil, stack)
        if not info then return msg, stack end
        if not class.Validate(target) then return "the target is not valid", stack end
        info[FLD_IC_DEBUGSR]    = true
    end

    local setModifiedFlag       = function (tType, target, flag, methodName, stack)
        local info, _, stack, msg = preDefineCheck(target, nil, stack)

        if not info then error(strformat("Usage: %s.%s(%s[, stack]) - ", tostring(tType), methodName, tostring(tType)) .. msg, stack + 2) end

        info[FLD_IC_MOD]        = turnOnFlags(flag, info[FLD_IC_MOD])
    end

    local setStaticMethod       = function (target, name, stack)
        local info, name, stack, msg = preDefineCheck(target, name, stack)

        if msg then return msg, stack end

        if info[name] == nil then
            info[FLD_IC_TYPMTD] = info[FLD_IC_TYPMTD] or {}
            info[name] = info[FLD_IC_TYPMTD][name]
            info[FLD_IC_TYPMTD][name] = false
            if info[FLD_IC_INHRTP] and info[FLD_IC_INHRTP][name] then info[FLD_IC_INHRTP][name] = nil end
        end
    end

    local setPriority           = function (target, name, priority, stack)
        local info, name, stack, msg = preDefineCheck(target, name, stack)
        if msg then return msg, stack end

        info[FLD_IC_INHRTP] = info[FLD_IC_INHRTP] or {}
        info[FLD_IC_INHRTP][name] = priority
    end

    -- Buidler helpers
    local setIFBuilderValue     = function (self, key, value, stack, notenvset)
        local owner = environment.GetNamespace(self)
        if not (owner and _ICBuilderInDefine[self]) then return end

        local tkey  = type(key)
        local tval  = type(value)

        stack       = stack + 1

        if tkey == "string" and not tonumber(key) then
            if META_KEYS[key] then
                interface.AddMetaData(owner, key, value, stack)
                return true
            elseif key == namespace.GetNamespaceName(owner, true) then
                interface.SetInitializer(owner, value, stack)
                return true
            elseif tval == "function" then
                interface.AddMethod(owner, key, value, stack)
                return true
            end

            if notenvset then
                for parser in pairs, _Parser do
                    if parser.Parse(owner, key, value, stack) then
                        return true
                    end
                end
            end
        elseif tkey == "number" then
            if tval == "table" or tval == "userdata" then
                if class.Validate(value) then
                    interface.SetRequireClass(owner, value, stack)
                    return true
                elseif interface.Validate(value) then
                    interface.AddExtend(owner, value, stack)
                    return true
                end
            elseif tval == "function" then
                interface.SetInitializer(owner, value, stack)
                return true
            end

            if notenvset then
                for parser in pairs, _Parser do
                    if parser.Parse(owner, key, value, stack) then
                        return true
                    end
                end
            end
        end
    end

    local setClassBuilderValue  = function (self, key, value, stack, notenvset)
        local owner = environment.GetNamespace(self)
        if not (owner and _ICBuilderInDefine[self]) then return end

        local tkey  = type(key)
        local tval  = type(value)

        stack       = stack + 1

        if tkey == "string" and not tonumber(key) then
            if META_KEYS[key] then
                class.AddMetaData(owner, key, value, stack)
                return true
            elseif key == namespace.GetNamespaceName(owner, true) then
                class.SetConstructor(owner, value, stack)
                return true
            elseif tval == "function" then
                class.AddMethod(owner, key, value, stack)
                return true
            end

            if notenvset then
                for parser in pairs, _Parser do
                    if parser.Parse(owner, key, value, stack) then
                        return true
                    end
                end
            end
        elseif tkey == "number" then
            if tval == "table" or tval == "userdata" then
                if class.Validate(value) then
                    class.SetSuperClass(owner, value, stack)
                    return true
                elseif interface.Validate(value) then
                    class.AddExtend(owner, value, stack)
                    return true
                end
            elseif tval == "function" then
                class.SetConstructor(owner, value, stack)
                return true
            end

            if notenvset then
                for parser in pairs, _Parser do
                    if parser.Parse(owner, key, value, stack) then
                        return true
                    end
                end
            end
        end
    end

    -----------------------------------------------------------------------
    --                             prototype                             --
    -----------------------------------------------------------------------
    interface                   = prototype {
        __tostring              = "interface",
        __index                 = {
            --- Add an interface to be extended
            -- @static
            -- @method  AddExtend
            -- @owner   interface
            -- @format  (target, extendinterface[, stack])
            -- @param   target                      the target interface
            -- @param   extendinterface             the interface to be extened
            -- @param   stack                       the stack level
            ["AddExtend"]       = function(target, extendinterface, stack)
                local msg, stack= addExtend(target, extendinterface, stack)
                if msg then error("Usage: interface.AddExtend(target, extendinterface[, stack]) - " .. msg, stack + 1) end
            end;

            --- Add a type feature to the the interface
            -- @static
            -- @method  AddFeature
            -- @owner   interface
            -- @format  (target, name, feature[, stack])
            -- @param   target                      the target interface
            -- @param   name                        the feature's name
            -- @param   feature                     the feature
            -- @param   stack                       the stack level
            ["AddFeature"]      = function(target, name, feature, stack)
                local msg, stack= addFeature(target, name, feature, stack)
                if msg then error("Usage: interface.AddFeature(target, name, feature[, stack]) - " .. msg, stack + 1) end
            end;

            --- Add init fields to the interface
            -- @static
            -- @method  AddFields
            -- @owner   interface
            -- @format  (target, fields[, stack])
            -- @param   target                      the target interface
            -- @param   fields:table                the init-fields
            -- @param   stack                       the stack level
            ["AddFields"]       = function(target, fields, stack)
                local msg, stack= addFields(target, fields, stack)
                if msg then error("Usage: interface.AddFields(target, fields[, stack]) - " .. msg, stack + 1) end
            end;

            --- Add a meta data to the interface
            -- @static
            -- @method  AddMetaData
            -- @owner   interface
            -- @format  (target, name, data[, stack])
            -- @param   target                      the target interface
            -- @param   name                        the meta name
            -- @param   data:(function|table)       the meta data
            -- @param   stack                       the stack level
            ["AddMetaData"]     = function(target, name, data, stack)
                local msg, stack= addMetaData(target, name, data, stack)
                if msg then error("Usage: interface.AddMetaData(target, name, data[, stack]) - " .. msg, stack + 1) end
            end;

            --- Add a method to the interface
            -- @static
            -- @method  AddMethod
            -- @owner   interface
            -- @format  (target, name, func[, stack])
            -- @param   target                      the target interface
            -- @param   name                        the method name
            -- @param   func:function               the method
            -- @param   stack                       the stack level
            ["AddMethod"]       = function(target, name, func, stack)
                local msg, stack= addMethod(target, name, func, stack)
                if msg then error("Usage: interface.AddMethod(target, name, func[, stack]) - " .. msg, stack + 1) end
            end;

            --- Begin the interface's definition
            -- @static
            -- @method  BeginDefinition
            -- @owner   interface
            -- @format  (target[, stack])
            -- @param   target                      the target interface
            -- @param   stack                       the stack level
            ["BeginDefinition"] = function(target, stack)
                stack = parsestack(stack) + 1

                target          = interface.Validate(target)
                if not target then error("Usage: interface.BeginDefinition(target[, stack]) - the target is not valid", stack) end

                if _ICInfo[target] and validateFlags(MOD_SEALED_IC, _ICInfo[target][FLD_IC_MOD]) then error(strformat("Usage: interface.BeginDefinition(target[, stack]) - the %s is sealed, can't be re-defined", tostring(target)), stack) end
                if _ICBuilderInfo[target] then error(strformat("Usage: interface.BeginDefinition(target[, stack]) - the %s's definition has already begun", tostring(target)), stack) end

                _ICBuilderInfo  = saveStorage(_ICBuilderInfo, target, getInitICInfo(target, false))

                attribute.SaveAttributes(target, ATTRTAR_INTERFACE, stack)
            end;

            --- Finish the interface's definition
            -- @static
            -- @method  EndDefinition
            -- @owner   interface
            -- @format  (target[, stack])
            -- @param   target                      the target interface
            -- @param   stack                       the stack level
            ["EndDefinition"]   = function(target, stack)
                local ninfo     = _ICBuilderInfo[target]
                if not ninfo then return end

                stack           = parsestack(stack) + 1

                attribute.InheritAttributes(target, ATTRTAR_INTERFACE, unpack(ninfo, FLD_IC_STEXT))
                attribute.ApplyAttributes  (target, ATTRTAR_INTERFACE, nil, nil, stack)

                genTypeCaches(target, ninfo, stack)

                -- End interface's definition
                _ICBuilderInfo  = saveStorage(_ICBuilderInfo, target, nil)

                -- Save as new interface's info
                saveICInfo(target, ninfo)

                attribute.AttachAttributes(target, ATTRTAR_INTERFACE, nil, nil, stack)

                reDefineChildren(target, stack)

                return target
            end;

            --- Refresh the interface's definition
            -- @static
            -- @method  EndDefinition
            -- @owner   interface
            -- @format  (target[, stack])
            -- @param   target                      the target interface
            -- @param   stack                       the stack level
            ["RefreshDefinition"] = function(target, stack)
                stack           = parsestack(stack) + 1

                target          = interface.Validate(target)
                if not target then error("Usage: interface.RefreshDefinition(interface[, stack]) - interface not existed", stack) end
                if _ICBuilderInfo[target] then error(strformat("Usage: interface.RefreshDefinition(interface[, stack]) - The %s's definition has already begun", tostring(target)), stack) end

                local ninfo     = getInitICInfo(target, false)

                genTypeCaches(target, ninfo, stack)

                -- Save as new interface's info
                saveICInfo(target, ninfo)

                reDefineChildren(target, stack)

                return target
            end;

            --- Get the definition context of the interface
            -- @static
            -- @method  GetDefault
            -- @return  prototype                   the context type
            ["GetDefinitionContext"] = function() return interfacebuilder end;

            --- Get all the extended interfaces of the target interface
            -- @static
            -- @method  GetExtends
            -- @owner   interface
            -- @format  (target[, cache])
            -- @param   target                      the target interface
            -- @param   cache                       the table used to save the result
            -- @rformat (cache)                     the cache that contains the interface list
            -- @rformat (iter, target)              without the cache parameter, used in generic for
            ["GetExtends"]      = function(target, cache)
                local info      = getICTargetInfo(target)
                if info then
                    if cache then
                        cache   = type(cache) == "table" and wipe(cache) or {}
                        for i   = #info, FLD_IC_STEXT, -1 do tinsert(cache, info[i]) end
                        return cache
                    else
                        local m = #info
                        local u = m - FLD_IC_STEXT
                        return function(self, n)
                            if type(n) == "number" and n >= 0 and n <= u then
                                return n + 1, info[m - n]
                            end
                        end, target, 0
                    end
                end
                if cache then
                    return type(cache) == "table" and cache or nil
                else
                    return fakefunc, target
                end
            end;

            --- Get a type feature of the target interface
            -- @static
            -- @method  GetFeature
            -- @owner   interface
            -- @param   (target, name[, fromobject])
            -- @param   target                      the target interface
            -- @param   name                        the feature's name
            -- @param   fromobject:boolean          get the object feature
            -- @return  feature                     the feature
            ["GetFeature"]      = function(target, name, fromobj)
                local info      = fromobj and _ICInfo[target] or getICTargetInfo(target)
                if info and type(name) == "string" then
                    info        = info[fromobj and FLD_IC_OBJFTR or FLD_IC_TYPFTR]
                    return info and info[name]
                end
            end;

            --- Get all the features of the target interface
            -- @static
            -- @method  GetFeatures
            -- @owner   interface
            -- @format  (target[, cache][, fromobject])
            -- @param   target                      the target interface
            -- @param   cache                       the table used to save the result
            -- @param   fromobject:boolean          get the object features
            -- @rformat (cache)                     the cache that contains the feature list
            -- @rformat (iter, target)              without the cache parameter, used in generic for
            ["GetFeatures"]     = function(target, cache, fromobj)
                local info      = fromobj and _ICInfo[target] or getICTargetInfo(target)
                if info then
                    local typftr= info[fromobj and FLD_IC_OBJFTR or FLD_IC_TYPFTR]
                    if cache then
                        cache   = type(cache) == "table" and wipe(cache) or {}

                        if typftr then for k, v in pairs, typftr do cache[k] = v end end

                        return cache
                    elseif typftr then
                        return function(self, n)
                            return next(typftr, n)
                        end, target
                    end
                end
                if cache then
                    return type(cache) == "table" and cache or nil
                else
                    return fakefunc, target
                end
            end;

            --- Get a method of the target interface
            -- @static
            -- @method  GetMethod
            -- @owner   interface
            -- @format  (target, name[, fromobject])
            -- @param   target                      the target interface
            -- @param   name                        the method's name
            -- @param   fromobject:boolean          get the object method
            -- @rformat method, isstatic
            -- @return  method                      the method
            -- @return  isstatic:boolean            whether the method is static
            ["GetMethod"]       = function(target, name, fromobj)
                local info      = fromobj and _ICInfo[target] or getICTargetInfo(target)
                if info and type(name) == "string" then
                    if not fromobj then
                        local mtd = info[name]
                        if mtd then return mtd, true end
                    end
                    info        = info[fromobj and FLD_IC_OBJMTD or FLD_IC_TYPMTD]
                    local mtd   = info and info[name]
                    if mtd then return mtd, false end
                end
            end;

            --- Get all the methods of the interface
            -- @static
            -- @method  GetMethods
            -- @owner   interface
            -- @format  (target[, cache][, fromobject])
            -- @param   target                      the target interface
            -- @param   cache                       the table used to save the result
            -- @param   fromobject:boolean          get the object methods
            -- @rformat (cache)                     the cache that contains the method list
            -- @rformat (iter, struct)              without the cache parameter, used in generic for
            -- @usage   for name, func, isstatic in interface.GetMethods(System.IAttribtue) do
            --              print(name)
            --          end
            ["GetMethods"]      = function(target, cache, fromobj)
                local info      = fromobj and _ICInfo[target] or getICTargetInfo(target)
                if info then
                    local typm  = info[fromobj and FLD_IC_OBJMTD or FLD_IC_TYPMTD]
                    if cache then
                        cache   = type(cache) == "table" and wipe(cache) or {}
                        if typm then for k, v in pairs, typm do cache[k] = v or info[k] end end
                        return cache
                    elseif typm then
                        return function(self, n)
                            local m, v = next(typm, n)
                            if m then return m, v or info[m], not v end
                        end, target
                    end
                end
                if cache then
                    return type(cache) == "table" and cache or nil
                else
                    return fakefunc, target
                end
            end;

            --- Get a meta-method of the target interface
            -- @static
            -- @method  GetMetaMethod
            -- @owner   interface
            -- @format  (target, name[, fromobject])
            -- @param   target                      the target interface
            -- @param   name                        the meta-method's name
            -- @param   fromobject:boolean          get the object meta-method
            -- @return  function                    the meta-method
            ["GetMetaMethod"]   = function(target, name, fromobj)
                local info      = fromobj and _ICInfo[target] or getICTargetInfo(target)
                local key       = META_KEYS[name]
                if info and key then
                    info        = info[fromobj and FLD_IC_OBJMTM or FLD_IC_TYPMTM]
                    return info and info[key]
                end
            end;

            --- Get all the meta-methods of the interface
            -- @static
            -- @method  GetMetaMethods
            -- @owner   interface
            -- @format  (target[, cache][, fromobject])
            -- @param   target                      the target interface
            -- @param   cache                       the table used to save the result
            -- @param   fromobject:boolean          get the object meta-methods
            -- @rformat (cache)                     the cache that contains the method list
            -- @rformat (iter, struct)              without the cache parameter, used in generic for
            ["GetMetaMethods"]      = function(target, cache, fromobj)
                local info      = fromobj and _ICInfo[target] or getICTargetInfo(target)
                if info then
                    local typm  = info[fromobj and FLD_IC_OBJMTM or FLD_IC_TYPMTM]
                    if cache then
                        cache   = type(cache) == "table" and wipe(cache) or {}
                        if typm then
                            for k in pairs, typm do local key = META_KEYS[k] if key then cache[k] = typm[key] end end end
                        return cache
                    elseif typm then
                        return function(self, n)
                            local m = next(typm, n)
                            while m and not META_KEYS[m] do m = next(typm, m) end
                            if m then return m, typm[META_KEYS[m]] end
                        end, target
                    end
                end
                if cache then
                    return type(cache) == "table" and cache or nil
                else
                    return fakefunc, target
                end
            end;

            --- Get the require class of the target interface
            -- @static
            -- @method  GetRequireClass
            -- @owner   interface
            -- @param   target                      the target interface
            -- @return  class                       the require class
            ["GetRequireClass"] = function(target)
                local info      = getICTargetInfo(target)
                return info and info[FLD_IC_REQCLS]
            end;

            --- Get the super method of the target interface with the given name
            -- @static
            -- @method  GetSuperMethod
            -- @owner   interface
            -- @param   target                      the target interface
            -- @param   name                        the method name
            -- @return  function                    the super method
            ["GetSuperMethod"]  = function(target, name)
                local info      = _ICInfo[target]
                return info and getSuperMethod(info, name)
            end;

            --- Get the super meta-method of the target interface with the given name
            -- @static
            -- @method  GetSuperMetaMethod
            -- @owner   interface
            -- @param   target                      the target interface
            -- @param   name                        the meta-method name
            -- @return  function                    the super meta-method
            ["GetSuperMetaMethod"] = function(target, name)
                local info      = _ICInfo[target]
                return info and getSuperMetaMethod(info, name)
            end;

            --- Get the super feature of the target interface with the given name
            -- @static
            -- @method  GetSuperFeature
            -- @owner   interface
            -- @param   target                      the target interface
            -- @param   name                        the feature name
            -- @return  function                    the super feature
            ["GetSuperFeature"] = function(target, name)
                local info      = _ICInfo[target]
                return info and getSuperFeature(info, name)
            end;

            --- Get the super refer of the target interface
            -- @static
            -- @method  GetSuperRefer
            -- @owner   interface
            -- @param   target                      the target interface
            -- @return  super                       the super refer
            ["GetSuperRefer"]   = function(target)
                local info      = getICTargetInfo(target)
                return info and info[FLD_IC_SUPER]
            end;

            --- Whether the interface has anonymous class
            -- @static
            -- @method  HasAnonymousClass
            -- @owner   interface
            -- @param   target                      the target interface
            -- @return  boolean                     true if the interface has anonymous class
            ["HasAnonymousClass"] = function(target)
                local info      = getICTargetInfo(target)
                return info and validateFlags(MOD_ANYMOUS_CLS, info[FLD_IC_MOD]) or false
            end;

            --- Whether the target interface is a sub-type of another interface
            -- @static
            -- @method  IsSubType
            -- @owner   interface
            -- @param   target                      the target interface
            -- @param   extendIF                    the extened interface
            -- @return  boolean                     true if the target interface is a sub-type of another interface
            ["IsSubType"]       = function(target, extendIF)
                if target == extendIF then return true end
                local info = getICTargetInfo(target)
                if info then for _, extif in ipairs, info, FLD_IC_STEXT - 1 do if extif == extendIF then return true end end end
                return false
            end;

            --- Whether the interface is final, can't be extended
            -- @static
            -- @method  IsFinal
            -- @owner   interface
            -- @param   target                      the target interface
            -- @return  boolean                     true if the interface is final
            ["IsFinal"]         = function(target)
                local info      = getICTargetInfo(target)
                return info and validateFlags(MOD_FINAL_IC, info[FLD_IC_MOD]) or false
            end;

            --- The objects are always immutable for type validation
            -- @static
            -- @method  IsImmutable
            -- @owner   interface
            -- @param   target                      the target interface
            -- @return  boolean                     true if the value should be immutable
            ["IsImmutable"]     = function(target)
                return true
            end;

            --- Whether the interface is sealed, can't be re-defined
            -- @static
            -- @method  IsSealed
            -- @owner   interface
            -- @param   target                      the target interface
            -- @return  boolean                     true if the interface is sealed
            ["IsSealed"]        = function(target)
                local info      = getICTargetInfo(target)
                return info and validateFlags(MOD_SEALED_IC, info[FLD_IC_MOD]) or false
            end;

            --- Whether the interface's given name method is static
            -- @static
            -- @method  IsStaticMethod
            -- @owner   interface
            -- @param   target                      the target interface
            -- @param   name                        the method's name
            -- @return  boolean                     true if the method is static
            ["IsStaticMethod"]  = function(target, name)
                local info      = getICTargetInfo(target)
                return info and type(name) == "string" and info[FLD_IC_TYPMTD] and info[FLD_IC_TYPMTD][name] == false or false
            end;

            --- Register a parser to analyse key-value pair as definition for the class or interface
            -- @static
            -- @method  IsStaticMethod
            -- @owner   interface
            -- @format  parser[, stack]
            -- @param   parser                      the parser
            -- @param   stack                       the stack level
            -- @return  boolean                     true if the key-value pair is accepted as definition
            ["RegisterParser"]  = function(parser, stack)
                stack           = parsestack(stack) + 1
                if not prototype.Validate(parser)           then error("Usage: interface.RegisterParser(parser[, stack] - the parser should be a prototype", stack) end
                if not getprototypemethod(parser, "Parse")  then error("Usage: interface.RegisterParser(parser[, stack] - the parser must have a 'Parse' method", stack) end
                _Parser         = saveStorage(_Parser, parser, true)
            end;

            --- Set the interface's method, meta-method or feature as abstract
            -- @static
            -- @method  SetAbstract
            -- @owner   interface
            -- @format  (target, name[, stack])
            -- @param   target                      the target interface
            -- @param   name                        the interface's method, meta-method or feature
            -- @param   stack                       the stack level
            ["SetAbstract"]     = function(target, name, stack)
                local msg, stack= setPriority(target, name, INRT_PRIORITY_ABSTRACT, stack)
                if msg then error("Usage: interface.SetAbstract(target, name[, stack]) - " .. msg, stack + 1) end
            end;

            --- Set the interface to have anonymous class
            -- @static
            -- @method  SetAnonymousClass
            -- @owner   interface
            -- @format  (target[, stack])
            -- @param   target                      the target interface
            -- @param   stack                       the stack level
            ["SetAnonymousClass"] = function(target, stack)
                setModifiedFlag(interface, target, MOD_ANYMOUS_CLS, "SetAnonymousClass", stack)
            end;

            --- Set the interface as final, or its method, meta-method or feature as final
            -- @static
            -- @method  SetFinal
            -- @owner   interface
            -- @format  (target[, stack])
            -- @format  (target, name[, stack])
            -- @param   target                      the target interface
            -- @param   name                        the interface's method, meta-method or feature
            -- @param   stack                       the stack level
            ["SetFinal"]        = function(target, name, stack)
                if type(name) == "string" then
                    local msg, stack= setPriority(target, name, INRT_PRIORITY_FINAL, stack)
                    if msg then error("Usage: interface.SetFinal(target, name[, stack]) - " .. msg, stack + 1) end
                else
                    stack = name
                    setModifiedFlag(interface, target, MOD_FINAL_IC, "SetFinal", stack)
                end
            end;

            --- Set the interface's destructor
            -- @static
            -- @method  SetDestructor
            -- @owner   interface
            -- @format  (target, func[, stack])
            -- @param   target                      the target interface
            -- @param   func:function               the destructor
            -- @param   stack                       the stack level
            ["SetDestructor"]   = function(target, func, stack)
                local msg, stack= addMetaData(target, IC_META_DTOR, func, stack)
                if msg then error("Usage: interface.SetDestructor(target, func[, stack]) - " .. msg, stack + 1) end
            end;

            --- Set the interface's initializer
            -- @static
            -- @method  SetInitializer
            -- @owner   interface
            -- @format  (target, func[, stack])
            -- @param   target                      the target interface
            -- @param   func:function               the initializer
            -- @param   stack                       the stack level
            ["SetInitializer"]  = function(target, func, stack)
                local msg, stack= addMetaData(target, IC_META_INIT, func, stack)
                if msg then error("Usage: interface.SetInitializer(target, func[, stack]) - " .. msg, stack + 1) end
            end;

            --- Set the require class to the interface
            -- @static
            -- @method  SetRequireClass
            -- @owner   interface
            -- @format  (target, requireclass[, stack])
            -- @param   target                      the target interface
            -- @param   requireclass                the require class
            -- @param   stack                       the stack level
            ["SetRequireClass"] = function(target, cls, stack)
                local msg, stack= setRequireClass(target, cls, stack)
                if msg then error("Usage: interface.SetRequireClass(target, requireclass[, stack]) - " .. msg, stack + 1) end
            end;

            --- Seal the interface
            -- @static
            -- @method  SetSealed
            -- @owner   interface
            -- @format  (target[, stack])
            -- @param   target                      the target interface
            -- @param   stack                       the stack level
            ["SetSealed"]       = function(target, stack)
                setModifiedFlag(interface, target, MOD_SEALED_IC, "SetSealed", stack)
            end;

            --- Mark the interface's method as static
            -- @static
            -- @method  SetStaticMethod
            -- @owner   interface
            -- @format  (target, name[, stack])
            -- @param   target                      the target interface
            -- @param   name                        the method's name
            -- @param   stack                       the stack level
            ["SetStaticMethod"] = function(target, name, stack)
                local msg, stack= setStaticMethod(target, name, stack)
                if msg then error("Usage: interface.SetStaticMethod(target, name[, stack]) - " .. msg, stack + 1) end
            end;

            --- Whether the value is an object whose class extend the interface
            -- @static
            -- @method  ValidateValue
            -- @owner   interface
            -- @format  (target, value[, onlyvalid])
            -- @param   target                      the target interface
            -- @param   value                       the value used to validate
            -- @param   onlyvalid                   if true use true instead of the error message
            -- @return  value                       the validated value, nil if not valid
            -- @return  error                       the error message if the value is not valid
            ["ValidateValue"]   = function(target, value, onlyvalid)
                if class.IsSubType(getmetatable(value), target) then return value end
                return nil, onlyvalid or ("the %s is not an object that extend the [interface]" .. tostring(target))
            end;

            -- Whether the target is an interface
            -- @static
            -- @method  Validate
            -- @owner   interface
            -- @param   target                      the target interface
            -- @return  target                      return the target if it's an interface, otherwise nil
            ["Validate"]        = function(target)
                return getmetatable(target) == interface and target or nil
            end;
        },
        __newindex              = readOnly,
        __call                  = function(self, ...)
            local visitor, env, target, definition, keepenv, stack = getTypeParams(interface, tinterface, ...)
            if not target then error("Usage: interface([env, ][name, ][definition, ][keepenv, ][stack]) - the interface type can't be created", stack) end

            stack               = stack + 1

            interface.BeginDefinition(target, stack)

            Debug("[interface] %s created", stack, tostring(target))

            local builder = prototype.NewObject(interfacebuilder)
            environment.Initialize  (builder)
            environment.SetNamespace(builder, target)
            environment.SetParent   (builder, env)

            _ICBuilderInDefine  = saveStorage(_ICBuilderInDefine, builder, true)

            if definition then
                builder(definition, stack)
                return target
            else
                if not keepenv then safesetfenv(stack, builder) end
                return builder
            end
        end,
    }

    class                       = prototype {
        __tostring              = "class",
        __index                 = {
            --- Add an interface to be extended
            -- @static
            -- @method  AddExtend
            -- @owner   class
            -- @format  (target, extendinterface[, stack])
            -- @param   target                      the target class
            -- @param   extendinterface             the interface to be extened
            -- @param   stack                       the stack level
            ["AddExtend"]       = function(target, extendinterface, stack)
                local msg, stack= addExtend(target, extendinterface, stack)
                if msg then error("Usage: class.AddExtend(target, extendinterface[, stack]) - " .. msg, stack + 1) end
            end;

            --- Add a type feature to the the class
            -- @static
            -- @method  AddFeature
            -- @owner   class
            -- @format  (target, name, feature[, stack])
            -- @param   target                      the target class
            -- @param   name                        the feature's name
            -- @param   feature                     the feature
            -- @param   stack                       the stack level
            ["AddFeature"]      = function(target, name, feature, stack)
                local msg, stack= addFeature(target, name, feature, stack)
                if msg then error("Usage: class.AddFeature(target, name, feature[, stack]) - " .. msg, stack + 1) end
            end;

            --- Add init fields to the class
            -- @static
            -- @method  AddFields
            -- @owner   class
            -- @format  (target, fields[, stack])
            -- @param   target                      the target class
            -- @param   fields:table                the init-fields
            -- @param   stack                       the stack level
            ["AddFields"]       = function(target, fields, stack)
                local msg, stack= addFields(target, fields, stack)
                if msg then error("Usage: class.AddFields(target, fields[, stack]) - " .. msg, stack + 1) end
            end;

            --- Add a meta data to the class
            -- @static
            -- @method  AddMetaData
            -- @owner   class
            -- @format  (target, name, data[, stack])
            -- @param   target                      the target class
            -- @param   name                        the meta name
            -- @param   data:(function|table)       the meta data
            -- @param   stack                       the stack level
            ["AddMetaData"]   = function(target, name, data, stack)
                local msg, stack= addMetaData(target, name, data, stack)
                if msg then error("Usage: class.AddMetaData(target, name, data[, stack]) - " .. msg, stack + 1) end
            end;

            --- Add a method to the class
            -- @static
            -- @method  AddMethod
            -- @owner   class
            -- @format  (target, name, func[, stack])
            -- @param   target                      the target class
            -- @param   name                        the method name
            -- @param   func:function               the method
            -- @param   stack                       the stack level
            ["AddMethod"]       = function(target, name, func, stack)
                local msg, stack= addMethod(target, name, func, stack)
                if msg then error("Usage: class.AddMethod(target, name, func[, stack]) - " .. msg, stack + 1) end
            end;

            --- Attach source place to the object
            -- @static
            -- method   AttachObjectSource
            -- @owner   class
            -- @format  (object[, stack])
            -- @param   object                      the target object
            -- @param   stack                       the stack level
            ["AttachObjectSource"] = function(object, stack)
                if type(object) ~= "table" then error("Usage: class.AttachObjectSource(object[, stack]) - the object is not valid", 2) end
                rawset(object, FLD_OBJ_SOURCE, getCallLine(parsestack(stack) + 1))
            end;

            --- Begin the class's definition
            -- @static
            -- @method  BeginDefinition
            -- @owner   class
            -- @format  (target[, stack])
            -- @param   target                      the target class
            -- @param   stack                       the stack level
            ["BeginDefinition"] = function(target, stack)
                stack           = parsestack(stack) + 1

                target          = class.Validate(target)
                if not target then error("Usage: class.BeginDefinition(target[, stack]) - the target is not valid", stack) end

                if _ICInfo[target] and validateFlags(MOD_SEALED_IC, _ICInfo[target][FLD_IC_MOD]) then error(strformat("Usage: class.BeginDefinition(target[, stack]) - The %s is sealed, can't be re-defined", tostring(target)), stack) end
                if _ICBuilderInfo[target] then error(strformat("Usage: class.BeginDefinition(target[, stack]) - The %s's definition has already begun", tostring(target)), stack) end

                _ICBuilderInfo  = saveStorage(_ICBuilderInfo, target, getInitICInfo(target, true))

                attribute.SaveAttributes(target, ATTRTAR_CLASS, stack)
            end;

            --- Finish the class's definition
            -- @static
            -- @method  EndDefinition
            -- @owner   class
            -- @format  (target[, stack])
            -- @param   target                      the target class
            -- @param   stack                       the stack level
            ["EndDefinition"]   = function(target, stack)
                local ninfo     = _ICBuilderInfo[target]
                if not ninfo then return end

                stack           = parsestack(stack) + 1

                attribute.InheritAttributes(target, ATTRTAR_CLASS, unpack(ninfo, ninfo[FLD_IC_SUPCLS] and FLD_IC_SUPCLS or FLD_IC_STEXT))
                attribute.ApplyAttributes  (target, ATTRTAR_CLASS, nil, nil, stack)

                -- Generate caches and constructor
                genTypeCaches(target, ninfo, stack)

                -- End class's definition
                _ICBuilderInfo  = saveStorage(_ICBuilderInfo, target, nil)

                -- Save as new interface's info
                saveICInfo(target, ninfo)

                attribute.AttachAttributes(target, ATTRTAR_CLASS, nil, nil, stack)

                reDefineChildren(target, stack)

                return target
            end;

            --- Get the definition context of the class
            -- @static
            -- @method  GetDefault
            -- @return  prototype                   the context type
            ["GetDefinitionContext"] = function() return classbuilder end;

            --- Get all the extended interfaces of the target class
            -- @static
            -- @method  GetExtends
            -- @owner   class
            -- @format  (target[, cache])
            -- @param   target                      the target class
            -- @param   cache                       the table used to save the result
            -- @rformat (cache)                     the cache that contains the interface list
            -- @rformat (iter, target)              without the cache parameter, used in generic for
            ["GetExtends"]      = interface.GetExtends;


            --- Get a type feature of the target class
            -- @static
            -- @method  GetFeature
            -- @owner   class
            -- @param   (target, name[, fromobject])
            -- @param   target                      the target class
            -- @param   name                        the feature's name
            -- @param   fromobject:boolean          get the object feature
            -- @return  feature                     the feature
            ["GetFeature"]      = interface.GetFeature;

            --- Get all the features of the target class
            -- @static
            -- @method  GetFeatures
            -- @owner   class
            -- @format  (target[, cache][, fromobject])
            -- @param   target                      the target class
            -- @param   cache                       the table used to save the result
            -- @param   fromobject:boolean          get the object features
            -- @rformat (cache)                     the cache that contains the feature list
            -- @rformat (iter, target)              without the cache parameter, used in generic for
            ["GetFeatures"]     = interface.GetFeatures;

            --- Get a method of the target class
            -- @static
            -- @method  GetMethod
            -- @owner   class
            -- @format  (target, name[, fromobject])
            -- @param   target                      the target class
            -- @param   name                        the method's name
            -- @param   fromobject:boolean          get the object method
            -- @rformat method, isstatic
            -- @return  method                      the method
            -- @return  isstatic:boolean            whether the method is static
            ["GetMethod"]       = interface.GetMethod;

            --- Get all the methods of the class
            -- @static
            -- @method  GetMethods
            -- @owner   class
            -- @format  (target[, cache][, fromobject])
            -- @param   target                      the target class
            -- @param   cache                       the table used to save the result
            -- @param   fromobject:boolean          get the object methods
            -- @rformat (cache)                     the cache that contains the method list
            -- @rformat (iter, struct)              without the cache parameter, used in generic for
            ["GetMethods"]      = interface.GetMethods;

            --- Get a meta-method of the target class
            -- @static
            -- @method  GetMetaMethod
            -- @owner   class
            -- @format  (target, name[, fromobject])
            -- @param   target                      the target class
            -- @param   name                        the meta-method's name
            -- @param   fromobject:boolean          get the object meta-method
            -- @return  function                    the meta-method
            ["GetMetaMethod"]   = interface.GetMetaMethod;

            --- Get all the meta-methods of the class
            -- @static
            -- @method  GetMetaMethods
            -- @owner   class
            -- @format  (target[, cache][, fromobject])
            -- @param   target                      the target class
            -- @param   cache                       the table used to save the result
            -- @param   fromobject:boolean          get the object meta-methods
            -- @rformat (cache)                     the cache that contains the method list
            -- @rformat (iter, struct)              without the cache parameter, used in generic for
            ["GetMetaMethods"]      = interface.GetMetaMethods;

            --- Get the object class of the object
            -- @static
            -- @method  GetObjectClass
            -- @owner   class
            -- @param   object                      the object
            -- @return  class                       the object class
            ["GetObjectClass"]      = function(object)
                return class.Validate(getmetatable(object))
            end;

            --- Get the object's creation place
            -- @static
            -- @method  GetObjectSource
            -- @owner   class
            -- @param   object                      the object
            -- @return  source                      where the object is created
            ["GetObjectSource"]     = function(object)
                return type(object) == "table" and rawget(object, FLD_OBJ_SOURCE) or nil
            end;

            --- Get the super class of the target class
            -- @static
            -- @method  GetSuperClass
            -- @owner   class
            -- @param   target                      the target class
            -- @return  class                       the super class
            ["GetSuperClass"]   = function(target)
                local info      = getICTargetInfo(target)
                return info and info[FLD_IC_SUPCLS]
            end;

            --- Get the super method of the target class with the given name
            -- @static
            -- @method  GetSuperMethod
            -- @owner   class
            -- @param   target                      the target class
            -- @param   name                        the method name
            -- @return  function                    the super method
            ["GetSuperMethod"]  = interface.GetSuperMethod;

            --- Get the super meta-method of the target class with the given name
            -- @static
            -- @method  GetSuperMetaMethod
            -- @owner   class
            -- @param   target                      the target class
            -- @param   name                        the meta-method name
            -- @return  function                    the super meta-method
            ["GetSuperMetaMethod"] = interface.GetSuperMetaMethod;

            --- Get the super feature of the target class with the given name
            -- @static
            -- @method  GetSuperFeature
            -- @owner   class
            -- @param   target                      the target class
            -- @param   name                        the feature name
            -- @return  function                    the super feature
            ["GetSuperFeature"] = interface.GetSuperFeature;

            --- Get the super refer of the target class
            -- @static
            -- @method  GetSuperRefer
            -- @owner   class
            -- @param   target                      the target class
            -- @return  super                       the super refer
            ["GetSuperRefer"]   = interface.GetSuperRefer;

            --- Get the this refer of the target class
            -- @static
            -- @method  GetThisRefer
            -- @owner   class
            -- @param   target                      the target class
            -- @return  this                        the this refer
            ["GetThisRefer"]    = function(target)
                local info      = getICTargetInfo(target)
                return info and info[FLD_IC_THIS]
            end;

            --- Whether the class is abstract, can't generate objects
            -- @static
            -- @method  IsAbstract
            -- @owner   class
            -- @param   target                      the target class
            -- @return  boolean                     true if the class is abstract
            ["IsAbstract"]      = function(target)
                local info      = getICTargetInfo(target)
                return info and validateFlags(MOD_ABSTRACT_CLS, info[FLD_IC_MOD]) or false
            end;

            --- Whether the class is final, can't be extended
            -- @static
            -- @method  IsFinal
            -- @owner   class
            -- @param   target                      the target class
            -- @return  boolean                     true if the class is final
            ["IsFinal"]         = interface.IsFinal;

            --- The objects are always immutable for type validation
            -- @static
            -- @method  IsImmutable
            -- @owner   class
            -- @param   target                      the target class
            -- @return  boolean                     true if the value should be immutable
            ["IsImmutable"]     = interface.IsImmutable;

            --- Whether the class object has enabled the attribute for functions will be defined in it
            -- @static
            -- @method  IsObjectFunctionAttributeEnabled
            -- @owner   class
            -- @param   target                      the target class
            -- @return  boolean                     true if the class object enabled the function attribute
            ["IsObjectFunctionAttributeEnabled"] = function(target)
                local info      = getICTargetInfo(target)
                return info and validateFlags(MOD_ATTRFUNC_OBJ, info[FLD_IC_MOD]) or false
            end;

            --- Whether the class object'll save its source when created
            -- @static
            -- @method  IsObjectSourceDebug
            -- @owner   class
            -- @param   target                      the target class
            -- @return  boolean                     true if the class object'll save its source when created
            ["IsObjectSourceDebug"] = function(target)
                local info      = getICTargetInfo(target)
                return info and info[FLD_IC_DEBUGSR] or false
            end;

            --- Whether the class object don't receive any value assignment excpet existed fields
            -- @static
            -- @method  IsRawSetBlocked
            -- @owner   class
            -- @param   target                      the target class
            -- @return  boolean                     true if the class object don't receive any value assignment excpet existed fields
            ["IsNilValueBlocked"] = function(target)
                local info      = getICTargetInfo(target)
                return info and validateFlags(MOD_NONILVAL_OBJ, info[FLD_IC_MOD]) or false
            end;

            --- Whether the class don't use super object access style like `Super[obj].Name = "Ann"`
            -- @static
            -- @method  IsNoSuperObjectStyle
            -- @owner   class
            -- @param   target                      the target class
            -- @return  boolean                     true if the class don't use super object access style
            ["IsNoSuperObjectStyle"] = function(target)
                local info      = getICTargetInfo(target)
                return info and validateFlags(MOD_NOSUPER_OBJ, info[FLD_IC_MOD]) or false
            end;

            --- Whether the class object don't receive any value assignment excpet existed fields
            -- @static
            -- @method  IsRawSetBlocked
            -- @owner   class
            -- @param   target                      the target class
            -- @return  boolean                     true if the class object don't receive any value assignment excpet existed fields
            ["IsRawSetBlocked"] = function(target)
                local info      = getICTargetInfo(target)
                return info and validateFlags(MOD_NORAWSET_OBJ, info[FLD_IC_MOD]) or false
            end;

            --- Whether the class is sealed, can't be re-defined
            -- @static
            -- @method  IsSealed
            -- @owner   class
            -- @param   target                      the target class
            -- @return  boolean                     true if the class is sealed
            ["IsSealed"]        = interface.IsSealed;

            --- Whether the class is a single version class, so old object would receive re-defined class's features
            -- @static
            -- @method  IsSingleVersion
            -- @owner   class
            -- @param   target                      the target class
            -- @return  boolean                     true if the class is a single version class
            ["IsSingleVersion"] = PLOOP_PLATFORM_SETTINGS.MULTI_OS_THREAD and function() return false end or function(target)
                local info      = getICTargetInfo(target)
                return info and validateFlags(MOD_SINGLEVER_CLS, info[FLD_IC_MOD]) or false
            end;

            --- Whether the class's given name method is static
            -- @static
            -- @method  IsStaticMethod
            -- @owner   class
            -- @param   target                      the target class
            -- @param   name                        the method's name
            -- @return  boolean                     true if the method is static
            ["IsStaticMethod"]  = interface.IsStaticMethod;

            --- Whether the target class is a sub-type of another interface or class
            -- @static
            -- @method  IsSubType
            -- @owner   class
            -- @format  (target, extendIF)
            -- @format  (target, superclass)
            -- @param   target                      the target class
            -- @param   extendIF                    the extened interface
            -- @param   superclass                  the super class
            -- @return  boolean                     true if the target class is a sub-type of another interface or class
            ["IsSubType"]       = function(target, supertype)
                if target == supertype then return true end
                local info = getICTargetInfo(target)
                if info then
                    if getmetatable(supertype) == class then
                        local sp= info[FLD_IC_SUPCLS]
                        while sp and sp ~= supertype do
                            sp  = getICTargetInfo(sp)[FLD_IC_SUPCLS]
                        end
                        return sp and true or false
                    else
                        for _, extif in ipairs, info, FLD_IC_STEXT - 1 do if extif == supertype then return true end end
                    end
                end
                return false
            end;

            --- Refresh the class's definition
            -- @static
            -- @method  EndDefinition
            -- @owner   class
            -- @format  (target[, stack])
            -- @param   target                      the target class
            -- @param   stack                       the stack level
            ["RefreshDefinition"] = function(target, stack)
                stack           = parsestack(stack) + 1

                target          = class.Validate(target)
                if not target then error("Usage: class.RefreshDefinition(target[, stack]) - the target is not valid", stack) end
                if _ICBuilderInfo[target] then error(strformat("Usage: class.RefreshDefinition(target[, stack]) - The %s's definition has already begun", tostring(target)), stack) end

                local ninfo     = getInitICInfo(target, true)

                -- Generate caches and constructor
                genTypeCaches(target, ninfo, stack)

                -- Save as new interface's info
                saveICInfo(target, ninfo)

                reDefineChildren(target, stack)

                return target
            end;

            --- Register a parser to analyse key-value pair as definition for the class or interface
            -- @static
            -- @method  IsStaticMethod
            -- @owner   class
            -- @format  parser[, stack]
            -- @param   parser                      the parser
            -- @param   stack                       the stack level
            -- @return  boolean                     true if the key-value pair is accepted as definition
            ["RegisterParser"]  = function(parser, stack)
                stack           = parsestack(stack) + 1
                if not prototype.Validate(parser)           then error("Usage: class.RegisterParser(parser[, stack] - the parser should be a prototype", stack) end
                if not getprototypemethod(parser, "Parse")  then error("Usage: class.RegisterParser(parser[, stack] - the parser must have a 'Parse' method", stack) end
                _Parser         = saveStorage(_Parser, parser, true)
            end;

            --- Set the class as abstract, or its method, meta-method or feature as abstract
            -- @static
            -- @method  SetAbstract
            -- @owner   class
            -- @format  (target[, stack])
            -- @format  (target, name[, stack])
            -- @param   target                      the target class
            -- @param   name                        the class's method, meta-method or feature
            -- @param   stack                       the stack level
            ["SetAbstract"]     = function(target, name, stack)
                if type(name) == "string" then
                    local msg, stack= setPriority(target, name, INRT_PRIORITY_ABSTRACT, stack)
                    if msg then error("Usage: class.SetAbstract(target, name[, stack]) - " .. msg, stack + 1) end
                else
                    stack = name
                    setModifiedFlag(class, target, MOD_ABSTRACT_CLS, "SetAbstract", stack)
                end
            end;

            --- Set the class's constructor
            -- @static
            -- @method  SetConstructor
            -- @owner   class
            -- @format  (target, func[, stack])
            -- @param   target                      the target class
            -- @param   func:function               the constructor
            -- @param   stack                       the stack level
            ["SetConstructor"]  = function(target, func, stack)
                local msg, stack= addMetaData(target, IC_META_CTOR, func, stack)
                if msg then error("Usage: class.SetConstructor(target, func[, stack]) - " .. msg, stack + 1) end
            end;

            --- Set the class's destructor
            -- @static
            -- @method  SetDestructor
            -- @owner   class
            -- @format  (target, func[, stack])
            -- @param   target                      the target class
            -- @param   func:function               the destructor
            -- @param   stack                       the stack level
            ["SetDestructor"]   = function(target, func, stack)
                local msg, stack= addMetaData(target, IC_META_DTOR, func, stack)
                if msg then
                    error("Usage: class.SetDestructor(class, func[, stack]) - " .. msg, stack + 1)
                end
            end;

            --- Set the class as final, or its method, meta-method or feature as final
            -- @static
            -- @method  SetFinal
            -- @owner   class
            -- @format  (target[, stack])
            -- @format  (target, name[, stack])
            -- @param   target                      the target class
            -- @param   name                        the class's method, meta-method or feature
            -- @param   stack                       the stack level
            ["SetFinal"]        = function(target, name, stack)
                if type(name) == "string" then
                    local msg, stack= setPriority(target, name, INRT_PRIORITY_FINAL, stack)
                    if msg then error("Usage: class.SetFinal(target, name[, stack]) - " .. msg, stack + 1) end
                else
                    stack = name
                    setModifiedFlag(class, target, MOD_FINAL_IC, "SetFinal", stack)
                end
            end;

            --- Set the class's object exist checker
            -- @static
            -- @method  SetObjectExistChecker
            -- @owner   class
            -- @format  (target, func[, stack])
            -- @param   target                      the target class
            -- @param   func:function               the object exist checker
            -- @param   stack                       the stack level
            ["SetObjectExistChecker"] = function(target, func, stack)
                local msg, stack= addMetaData(target, IC_META_EXIST, func, stack)
                if msg then error("Usage: class.SetObjectExistChecker(target, func[, stack]) - " .. msg, stack + 1) end
            end;

            --- Make the class objects enable the attribute for functions will be defined in it
            -- @static
            -- @method  SetObjectFunctionAttributeEnabled
            -- @owner   class
            -- @format  (target[, stack])
            -- @param   target                      the target class
            -- @param   stack                       the stack level
            ["SetObjectFunctionAttributeEnabled"] = function(target, stack)
                setModifiedFlag(class, target, MOD_ATTRFUNC_OBJ, "SetObjectFunctionAttributeEnabled", stack)
            end;

            --- Set the class's object generator
            -- @static
            -- @method  SetObjectGenerator
            -- @owner   class
            -- @format  (target, func[, stack])
            -- @param   target                      the target class
            -- @param   func:function               the object generator
            -- @param   stack                       the stack level
            ["SetObjectGenerator"] = function(target, func, stack)
                local msg, stack= addMetaData(target, IC_META_NEW, func, stack)
                if msg then error("Usage: class.SetObjectGenerator(target, func[, stack]) - " .. msg, stack + 1) end
            end;

            --- Make the class object don't receive any value assignment excpet existed fields
            -- @static
            -- @method  SetNilValueBlocked
            -- @owner   class
            -- @format  (target[, stack])
            -- @param   target                      the target class
            -- @param   stack                       the stack level
            ["SetNilValueBlocked"] = function(target, stack)
                setModifiedFlag(class, target, MOD_NONILVAL_OBJ, "SetNilValueBlocked", stack)
            end;

            --- Make the class don't use super object access style like `Super[obj].Name = "Ann"`
            -- @static
            -- @method  SetNoSuperObject
            -- @owner   class
            -- @format  (target[, stack])
            -- @param   target                      the target class
            -- @param   stack                       the stack level
            ["SetNoSuperObject"]= function(target, stack)
                setModifiedFlag(class, target, MOD_NOSUPER_OBJ, "SetNoSuperObject", stack)
            end;

            --- Make the class object don't receive any value assignment excpet existed fields
            -- @static
            -- @method  IsRawSetBlocked
            -- @owner   class
            -- @format  (target[, stack])
            -- @param   target                      the target class
            -- @param   stack                       the stack level
            ["SetRawSetBlocked"]= function(target, stack)
                setModifiedFlag(class, target, MOD_NORAWSET_OBJ, "SetRawSetBlocked", stack)
            end;

            --- Seal the class
            -- @static
            -- @method  SetSealed
            -- @owner   class
            -- @format  (target[, stack])
            -- @param   target                      the target class
            -- @param   stack                       the stack level
            ["SetSealed"]       = function(target, stack)
                setModifiedFlag(class, target, MOD_SEALED_IC, "SetSealed", stack)
            end;

            --- Set the class as single version, so old object would receive re-defined class's features
            -- @static
            -- @method  SetSingleVersion
            -- @owner   class
            -- @format  (target[, stack])
            -- @param   target                      the target class
            -- @param   stack                       the stack level
            ["SetSingleVersion"]= PLOOP_PLATFORM_SETTINGS.MULTI_OS_THREAD and fakefunc or function(target, stack)
                setModifiedFlag(class, target, MOD_SINGLEVER_CLS, "SetSingleVersion", stack)
            end;

            --- Set the super class to the class
            -- @static
            -- @method  SetRequireClass
            -- @owner   class
            -- @format  (target, superclass[, stack])
            -- @param   target                      the target class
            -- @param   superclass                  the super class
            -- @param   stack                       the stack level
            ["SetSuperClass"]   = function(target, cls, stack)
                local msg, stack= setSuperClass(target, cls, stack)
                if msg then error("Usage: class.SetSuperClass(target, superclass[, stack])  - " .. msg, stack + 1) end
            end;

            --- Set the class object'll to save its source when created
            -- @static
            -- @method  SetObjectSourceDebug
            -- @owner   class
            -- @format  (target[, stack])
            -- @param   target                      the target class
            -- @param   stack                       the stack level
            ["SetObjectSourceDebug"]= function(target, stack)
                local msg, stack    = setObjectSourceDebug(target, stack)
                if msg then error("Usage: class.SetObjectSourceDebug(target[, stack])  - " .. msg, stack + 1) end
            end;

            --- Mark the class's method as static
            -- @static
            -- @method  SetStaticMethod
            -- @owner   class
            -- @format  (target, name[, stack])
            -- @param   target                      the target class
            -- @param   name                        the method's name
            -- @param   stack                       the stack level
            ["SetStaticMethod"] = function(target, name, stack)
                local msg, stack= setStaticMethod(target, name, stack)
                if msg then error("Usage: class.SetStaticMethod(class, name[, stack]) - " .. msg, stack + 1) end
            end;

            --- Whether the value is an object whose class inherit the target class
            -- @static
            -- @method  ValidateValue
            -- @owner   class
            -- @format  (target, value[, onlyvalid])
            -- @param   target                      the target class
            -- @param   value                       the value used to validate
            -- @param   onlyvalid                   if true use true instead of the error message
            -- @return  value                       the validated value, nil if not valid
            -- @return  error                       the error message if the value is not valid
            ["ValidateValue"]   = function(target, value, onlyvalid)
                if class.IsSubType(getmetatable(value), target) then return value end
                return nil, onlyvalid or ("the %s is not an object of the [class]" .. tostring(target))
            end;

            -- Whether the target is a class
            -- @static
            -- @method  Validate
            -- @owner   class
            -- @param   target                      the target class
            -- @return  target                      return the target if it's a class, otherwise nil
            ["Validate"]        = function(target)
                return getmetatable(target) == class and target or nil
            end;
        },
        __newindex              = readOnly,
        __call                  = function(self, ...)
            local visitor, env, target, definition, keepenv, stack = getTypeParams(class, tclass, ...)
            if not target then error("Usage: class([env, ][name, ][definition, ][keepenv, ][stack]) - the class type can't be created", stack) end

            stack               = stack + 1

            class.BeginDefinition(target, stack)

            Debug("[class] %s created", stack, tostring(target))

            local builder = prototype.NewObject(classbuilder)
            environment.Initialize  (builder)
            environment.SetNamespace(builder, target)
            environment.SetParent   (builder, env)

            _ICBuilderInDefine  = saveStorage(_ICBuilderInDefine, builder, true)

            if definition then
                builder(definition, stack)
                return target
            else
                if not keepenv then safesetfenv(stack, builder) end
                return builder
            end
        end,
    }

    tinterface                  = prototype (tnamespace, {
        __index                 = function(self, key)
            if type(key) == "string" then
                -- Access methods
                local info      = _ICBuilderInfo[self] or _ICInfo[self]
                if info then
                    -- Static or object methods
                    local oper  = info[key] or info[FLD_IC_TYPMTD] and info[FLD_IC_TYPMTD][key]
                    if oper then return oper end

                    -- Static features
                    oper        = info[FLD_IC_STAFTR] and info[FLD_IC_STAFTR][key]
                    if oper then return oper:Get(self) end
                end

                -- Access child-namespaces
                return namespace.GetNamespace(self, key)
            end
        end,
        __newindex              = function(self, key, value)
            if type(key) == "string" then
                local info      = _ICInfo[self]

                if info then
                    -- Static features
                    local oper  = info[FLD_IC_STAFTR] and info[FLD_IC_STAFTR][key]
                    if oper then oper:Set(self, value) return end

                    -- Try add methods
                    if type(value) == "function" then
                        getmetatable(self).AddMethod(self, key, value, 2)
                        return
                    end
                end
            end

            error(strformat("The %s is readonly", tostring(self)), 2)
        end,
        __call                  = function(self, init)
            local info  = _ICInfo[self]
            local aycls = info[FLD_IC_ANYMSCL]
            if not aycls then error(strformat("Usage: the %s doesn't have anonymous class", tostring(self)), 2) end

            if type(init) == "function" then
                local abs = info[FLD_IC_ONEABS]
                if not abs then error(strformat("Usage: %s([init]) - the interface doesn't have only one abstract method", tostring(self)), 2) end
                init    = { [abs] = init }
            elseif init and type(init) ~= "table" then
                error(strformat("Usage: %s([init]) - the init can only be a table", tostring(self)), 2)
            end

            return aycls(init)
        end,
        __metatable             = interface,
    })

    tclass                      = prototype (tinterface, {
        __call                  = function(self, ...)
            local info          = _ICInfo[self]
            local ok, obj       = pcall(info[FLD_IC_OBCTOR], info, ...)
            if not ok then
                if type(obj)  == "string" then
                    error(obj, 0)
                else
                    error(tostring(obj), 2)
                end
            end
            if info[FLD_IC_DEBUGSR] then
                local src       = getCallLine(2)
                if src then rawset(obj, FLD_OBJ_SOURCE, src) end
            end
            return obj
        end,
        __metatable             = class,
    })

    tsuperinterface             = prototype {
        __tostring              = function(self) return tostring(_SuperMap[self]) end,
        __index                 = function(self, key)
            local t = type(key)

            if t == "string" then
                local info  = _ICInfo[_SuperMap[self]]
                local f     = info[FLD_IC_SUPMTD]
                return f and f[key]
            elseif t == "table" then
                rawset(key, OBJ_SUPER_ACCESS, _SuperMap[self])
                return key
            end
        end,
        __newindex              = readOnly,
        __metatable             = interface,
    }

    tsuperclass                 = prototype (tsuperinterface, {
        __call                  = function(self, obj, ...)
            local cls           = _SuperMap[self]
            if obj and class.IsSubType(getmetatable(obj), cls) then
                local spcls     = _ICInfo[cls][FLD_IC_SUPCLS]
                if spcls then
                    local ctor  = _ICInfo[spcls][FLD_IC_CLINIT]
                    if ctor then return ctor(obj, ...) end
                else
                    error(strformat("Usage: super(object, ..) - the %s has no super class", tostring(cls)), 2)
                end
            else
                error("Usage: super(object, ..) - the object is not valid", 2)
            end
        end,
        __metatable             = class,
    })

    tthisclass                  = prototype {
        __tostring              = function(self) return tostring(_ThisMap[self]) end,
        __call                  = function(self, obj, ...)
            local cls           = _ThisMap[self]
            if obj and getmetatable(obj) == cls then
                local ctor      = _ICInfo[cls][FLD_IC_CTOR]
                if ctor then return ctor(obj, ...) end
            else
                error("Usage: this(object, ..) - the object is not valid", 2)
            end
        end,
        __metatable             = class,
    }

    interfacebuilder            = prototype {
        __tostring              = function(self)
            local owner         = environment.GetNamespace(self)
            return "[interfacebuilder]" .. (owner and tostring(owner) or "anonymous")
        end,
        __index                 = function(self, key)
            local value         = getEnvValue(self, key, _ICBuilderInDefine[self], 2)
            return value
        end,
        __newindex              = function(self, key, value)
            if not setIFBuilderValue(self, key, value, 2) then
                return rawset(self, key, value)
            end
        end,
        __call                  = function(self, definition, stack)
            stack               = parsestack(stack) + 1
            if not definition then error("Usage: interface([env, ][name, ][stack]) (definition) - the definition is missing", stack) end

            local owner         = environment.GetNamespace(self)
            if not (owner and _ICBuilderInDefine[self] and _ICBuilderInfo[owner]) then error("The interface's definition is finished", stack) end

            definition = parseDefinition(attribute.InitDefinition(owner, ATTRTAR_INTERFACE, definition, nil, nil, stack), self, stack)

            if type(definition) == "function" then
                setfenv(definition, self)
                definition(self)
            else
                -- Index key
                for i, v in ipairs, definition, 0 do
                    setIFBuilderValue(self, i, v, stack, true)
                end

                for k, v in pairs, definition do
                    if type(k) == "string" then
                        setIFBuilderValue(self, k, v, stack, true)
                    end
                end
            end

            _ICBuilderInDefine = saveStorage(_ICBuilderInDefine, self, nil)
            interface.EndDefinition(owner, stack)

            -- Save super refer
            local super = interface.GetSuperRefer(owner)
            if super then rawset(self, IC_KEYWORD_SUPER, super) end

            if getfenv(stack) == self then
                safesetfenv(stack, environment.GetParent(self) or _G)
            end

            return owner
        end,
    }

    classbuilder                = prototype {
        __tostring              = function(self)
            local owner         = environment.GetNamespace(self)
            return "[classbuilder]" .. (owner and tostring(owner) or "anonymous")
        end,
        __index                 = function(self, key)
            local value         = getEnvValue(self, key, _ICBuilderInDefine[self], 2)
            return value
        end,
        __newindex              = function(self, key, value)
            if not setClassBuilderValue(self, key, value, 2) then
                return rawset(self, key, value)
            end
        end,
        __call                  = function(self, definition, stack)
            stack               = parsestack(stack) + 1
            if not definition then error("Usage: class([env, ][name, ][stack]) (definition) - the definition is missing", stack) end

            local owner         = environment.GetNamespace(self)
            if not (owner and _ICBuilderInDefine[self] and _ICBuilderInfo[owner]) then error("The class's definition is finished", stack) end

            definition = parseDefinition(attribute.InitDefinition(owner, ATTRTAR_CLASS, definition, nil, nil, stack), self, stack)

            if type(definition) == "function" then
                setfenv(definition, self)
                definition(self)
            else
                -- Index key
                for i, v in ipairs, definition, 0 do
                    setClassBuilderValue(self, i, v, stack, true)
                end

                for k, v in pairs, definition do
                    if type(k) == "string" then
                        setClassBuilderValue(self, k, v, stack, true)
                    end
                end
            end

            _ICBuilderInDefine = saveStorage(_ICBuilderInDefine, self, nil)
            class.EndDefinition(owner, stack)

            -- Save super refer
            local super = class.GetSuperRefer(owner)
            if super then rawset(self, IC_KEYWORD_SUPER, super) end

            -- Save this refer
            local this  = class.GetThisRefer(owner)
            if this then rawset(self, IC_KEYWORD_THIS, this) end

            if getfenv(stack) == self then
                safesetfenv(stack, environment.GetParent(self) or _G)
            end

            return owner
        end,
    }

    -----------------------------------------------------------------------
    --                             keywords                              --
    -----------------------------------------------------------------------

    -----------------------------------------------------------------------
    -- extend an interface to the current class or interface
    --
    -- @keyword     extend
    -- @usage       extend "System.IAttribute"
    -----------------------------------------------------------------------
    extend                      = function (...)
        local visitor, env, name, _, flag, stack  = getFeatureParams(extend, namespace, ...)

        name = parseNamespace(name, visitor, env)
        if not name then error("Usage: extend(interface) - The interface is not provided", stack + 1) end

        local owner = visitor and environment.GetNamespace(visitor)
        if not owner  then error("Usage: extend(interface) - The system can't figure out the class or interface", stack + 1) end

        interface.AddExtend(owner, name, stack + 1)

        return visitor.extend
    end

    -----------------------------------------------------------------------
    -- Add init fields to the class or interface
    --
    -- @keyword     field
    -- @usage       field { Test = 123, Any = true }
    -----------------------------------------------------------------------
    field                       = function (...)
        local visitor, env, name, definition, flag, stack = getFeatureParams(field, nil, ...)

        if type(definition) ~= "table" then error("Usage: field { key-value pairs } - The field only accept table as definition", stack + 1) end

        local owner = visitor and environment.GetNamespace(visitor)

        if owner then
            if class.Validate(owner) then
                class.AddFields(owner, definition, stack + 1)
                return
            elseif interface.Validate(owner) then
                interface.AddFields(owner, definition, stack + 1)
                return
            end
        end

        error("Usage: field { key-value pairs } - The field can't be used here", stack + 1)
    end

    -----------------------------------------------------------------------
    -- inherit a super class to the current class
    --
    -- @keyword     inherit
    -- @usage       inherit "System.Object"
    -----------------------------------------------------------------------
    inherit                      = function (...)
        local visitor, env, name, _, flag, stack  = getFeatureParams(inherit, namespace, ...)

        name = parseNamespace(name, visitor, env)
        if not name then error("Usage: inherit(class) - The class is not provided", stack + 1) end

        local owner = visitor and environment.GetNamespace(visitor)
        if not owner  then error("Usage: inherit(class) - The system can't figure out the class", stack + 1) end

        class.SetSuperClass(owner, name, stack + 1)
    end

    -----------------------------------------------------------------------
    -- set the require class to the interface
    --
    -- @keyword     require
    -- @usage       require "System.Object"
    -----------------------------------------------------------------------
    require                      = function (...)
        local visitor, env, name, _, flag, stack  = getFeatureParams(require, namespace, ...)

        name = parseNamespace(name, visitor, env)
        if not name then error("Usage: require(class) - The class is not provided", stack + 1) end

        local owner = visitor and environment.GetNamespace(visitor)
        if not owner  then error("Usage: require(class) - The system can't figure out the interface", stack + 1) end

        interface.SetRequireClass(owner, name, stack + 1)
    end

    -----------------------------------------------------------------------
    -- End the definition of the interface
    --
    -- @keyword     endinterface
    -- @usage       interface "IA"
    --                  function IA(self)
    --                  end
    --              endinterface "IA"
    -----------------------------------------------------------------------
    endinterface                = PLOOP_PLATFORM_SETTINGS.TYPE_DEFINITION_WITH_OLD_STYLE and function (...)
        local visitor, env, name, definition, flag, stack  = getFeatureParams(endinterface, nil,  ...)
        local owner = visitor and environment.GetNamespace(visitor)

        stack = stack + 1

        if not owner or not visitor then error([[Usage: endinterface "name" - can't be used here.]], stack) end
        if namespace.GetNamespaceName(owner, true) ~= name then error(strformat("%s's definition isn't finished", tostring(owner)), stack) end

        _ICBuilderInDefine = saveStorage(_ICBuilderInDefine, visitor, nil)
        interface.EndDefinition(owner, stack)

        -- Save super refer
        local super = interface.GetSuperRefer(owner)
        if super then rawset(visitor, IC_KEYWORD_SUPER, super) end

        local baseEnv       = environment.GetParent(visitor) or _G

        setfenv(stack, baseEnv)

        return baseEnv
    end or nil

    -----------------------------------------------------------------------
    -- End the definition of the class
    --
    -- @keyword     endclass
    -- @usage       class "IA"
    --                  function IA(self)
    --                  end
    --              endclass "IA"
    -----------------------------------------------------------------------
    endclass                    = PLOOP_PLATFORM_SETTINGS.TYPE_DEFINITION_WITH_OLD_STYLE and function (...)
        local visitor, env, name, definition, flag, stack  = getFeatureParams(endclass, nil,  ...)
        local owner = visitor and environment.GetNamespace(visitor)

        stack = stack + 1

        if not owner or not visitor then error([[Usage: endclass "name" - can't be used here.]], stack) end
        if namespace.GetNamespaceName(owner, true) ~= name then error(strformat("%s's definition isn't finished", tostring(owner)), stack) end

        _ICBuilderInDefine = saveStorage(_ICBuilderInDefine, visitor, nil)
        class.EndDefinition(owner, stack)

        -- Save super refer
        local super = class.GetSuperRefer(owner)
        if super then rawset(visitor, IC_KEYWORD_SUPER, super) end

        -- Save this refer
        local this  = class.GetThisRefer(owner)
        if this then rawset(visitor, IC_KEYWORD_THIS, this) end

        local baseEnv       = environment.GetParent(visitor) or _G

        setfenv(stack, baseEnv)

        return baseEnv
    end or nil
end

-------------------------------------------------------------------------------
-- The events are used to notify the outside that the state of class object has
-- changed. Let's take an example to start :
--
--              class "Person" (function(_ENV)
--                  event "OnNameChanged"
--
--                  field { name = "anonymous" }
--
--                  function SetName(self, name)
--                      if name ~= self.name then
--                          -- Notify the outside
--                          OnNameChanged(self, name, self.name)
--                          self.name = name
--                      end
--                  end
--              end)
--
--              o = Person()
--
--              -- Bind a function as handler to the event
--              function o:OnNameChanged(new, old)
--                  print(("Renamed from %q to %q"):format(old, new))
--              end
--
--              -- Renamed from "anonymous" to "Ann"
--              o:SetName("Ann")
--
-- The event is a feature type of the class and interface, there are two types
-- of the event handler :
--      * the final handler - the previous example has shown how to bind the
--          final handler.
--      * the stackable handler - The stackable handler are normally used in
--          the class's constructor or interface's initializer:
--
--              class "Student" (function(_ENV)
--                  inherit "Person"
--
--                  local function onNameChanged(self, name, old)
--                      print(("Student %s renamed to %s"):format(old, name))
--                  end
--
--                  function Student(self, name)
--                      self:SetName(name)
--                      self.OnNameChanged = self.OnNameChanged + onNameChanged
--                  end
--              end)
--
--              o = Student("Ann")
--
--              function o:OnNameChanged(name)
--                  print("My new name is " .. name)
--              end
--
--              -- Student Ann renamed to Ammy
--              -- My new name is Ammy
--              o:SetName("Ammy")
--
-- The `self.OnNameChanged` is an object generated by **System.Delegate** who
-- has `__add` and `__sub` meta-methods so it can works with the style like
--
--              self.OnNameChanged = self.OnNameChanged + onNameChanged
-- or
--
--              self.OnNameChanged = self.OnNameChanged - onNameChanged
--
-- The stackable handlers are added with orders, so the super class's handler'd
-- be called at first then the class's, then the interface's. The final handler
-- will be called at the last, if any handler `return true`, the call process
-- will be ended.
--
-- In some scenarios, we need to block the object's event, the **Delegate** can
-- set an init function that'd be called before all other handlers, we can use
--
--              self.OnNameChanged:SetInitFunction(function() return true end)
--
-- To block the object's *OnNameChanged* event.
--
-- When using PLoop to wrap objects generated from other system, we may need to
-- bind the PLoop event to other system's event, there is two parts in it :
--      * When the PLoop object's event handlers are changed, we need know when
--  and whether there is any handler for that event, so we can register or
--  un-register in the other system.
--      * When the event of the other system is triggered, we need invoke the
--  PLoop's event.
--
-- Take the *Frame* widget from the *World of Warcraft* as an example, ignore
-- the other details, let's focus on the event two-way binding :
--
--              class "Frame" (function(_ENV)
--                  __EventChangeHandler__(function(delegate, owner, eventname)
--                      -- owner is the frame object
--                      -- eventname is the OnEnter for this case
--                      if delegate:IsEmpty() then
--                          -- No event handler, so un-register the frame's script event
--                          owner:SetScript(eventname, nil)
--                      else
--                          -- Has event handler, so we must regiser the frame's script event
--                          if owner:GetScript(eventname) == nil then
--                              owner:SetScript(eventname, function(self, ...)
--                                  -- Call the delegate directly
--                                  delegate(self, ...)
--                              end)
--                          end
--                      end
--                  end)
--                  event "OnEnter"
--              end)
--
-- With the `__EventChangeHandler__` attribute, we can bind a function to the
-- target event, so all changes of the event handlers can be checked in the
-- function. Since the event change handler has nothing special with the target
-- event, we can use it on all script events in one system like :
--
--              -- A help class so it can be saved in namespaces
--              class "__WidgetEvent__" (function(_ENV)
--                  local function handler (delegate, owner, eventname)
--                      if delegate:IsEmpty() then
--                          owner:SetScript(eventname, nil)
--                      else
--                          if owner:GetScript(eventname) == nil then
--                              owner:SetScript(eventname, function(self, ...)
--                                  -- Call the delegate directly
--                                  delegate(self, ...)
--                              end)
--                          end
--                      end
--                  end
--
--                  function __WidgetEvent__(self)
--                      __EventChangeHandler__(handler)
--                  end
--              end)
--
--              class "Frame" (function(_ENV)
--                  __WidgetEvent__()
--                  event "OnEnter"
--
--                  __WidgetEvent__()
--                  event "OnLeave"
--              end)
--
--
-- The event can also be marked as static, so it can be used and only be used by
-- the class or interface :
--
--              class "Person" (function(_ENV)
--                  __Static__()
--                  event "OnPersonCreated"
--
--                  function Person(self, name)
--                      OnPersonCreated(name)
--                  end
--              end)
--
--              function Person.OnPersonCreated(name)
--                  print("Person created " .. name)
--              end
--
--              -- Person created Ann
--              o = Person("Ann")
--
-- When the class or interface has overridden the event, and they need register
-- handler to super event, we can use the super object access style :
--
--              class "Person" (function(_ENV)
--                  property "Name" { event = "OnNameChanged" }
--              end)
--
--              class "Student" (function(_ENV)
--                  inherit "Person"
--
--                  event "OnNameChanged"
--
--                  local function raiseEvent(self, ...)
--                      OnNameChanged(self, ...)
--                  end
--
--                  function Student(self)
--                      super(self)
--
--                      -- Use the super object access style
--                      super[self].OnNameChanged = raiseEvent
--                  end
--              end)
--
--              o = Student()
--
--              function o:OnNameChanged(name)
--                  print("New name is " .. name)
--              end
--
--              -- New name is Test
--              o.Name = "Test"
--
-- @prototype   event
-------------------------------------------------------------------------------
do
    -----------------------------------------------------------------------
    --                         attribute targets                         --
    -----------------------------------------------------------------------
    ATTRTAR_EVENT               = attribute.RegisterTargetType("Event")

    -----------------------------------------------------------------------
    --                         private constants                         --
    -----------------------------------------------------------------------
    local FLD_EVENT_HANDLER     = 0
    local FLD_EVENT_NAME        = 1
    local FLD_EVENT_FIELD       = 2
    local FLD_EVENT_OWNER       = 3
    local FLD_EVENT_STATIC      = 4
    local FLD_EVENT_DELEGATE    = 5

    local FLD_EVENT_META        = "__PLOOP_EVENT_META"
    local FLD_EVENT_PREFIX      = "__PLOOP_EVENT_"

    -----------------------------------------------------------------------
    --                          private storage                          --
    -----------------------------------------------------------------------
    local _EventInfo            = PLOOP_PLATFORM_SETTINGS.UNSAFE_MODE
                                    and setmetatable({}, {__index = function(_, c) return type(c) == "table" and rawget(c, FLD_EVENT_META) or nil end})
                                    or  newStorage(WEAK_KEY)

    local _EventInDefine        = newStorage(WEAK_KEY)

    -----------------------------------------------------------------------
    --                          private helpers                          --
    -----------------------------------------------------------------------
    local saveEventInfo         = PLOOP_PLATFORM_SETTINGS.UNSAFE_MODE
                                    and function(target, info) rawset(target, FLD_EVENT_META, info) end
                                    or  function(target, info) _EventInfo = saveStorage(_EventInfo, target, info) end

    local genEvent              = function(owner, name, value, stack)
        local evt               = prototype.NewProxy(tevent)
        local info              = {
            [FLD_EVENT_NAME]    = name,
            [FLD_EVENT_FIELD]   = FLD_EVENT_PREFIX .. namespace.GetNamespaceName(owner, true) .. "_" .. name,
            [FLD_EVENT_OWNER]   = owner,
            [FLD_EVENT_STATIC]  = value or nil,
        }

        stack                   = stack + 1

        saveEventInfo(evt, info)

        _EventInDefine          = saveStorage(_EventInDefine, evt, true)

        attribute.SaveAttributes(evt, ATTRTAR_EVENT, stack + 1)

        local super             = interface.GetSuperFeature(owner, name)
        if super and event.Validate(super) then attribute.InheritAttributes(evt, ATTRTAR_EVENT, super) end
        attribute.ApplyAttributes(evt, ATTRTAR_EVENT, owner, name, stack)

        _EventInDefine          = saveStorage(_EventInDefine, evt, nil)

        -- Convert to static event
        if not value and event.IsStatic(evt) then
            saveEventInfo(evt, nil)
            local new           = prototype.NewProxy(tsevent)
            attribute.ToggleTarget(evt, new)
            evt                 = new
            saveEventInfo(evt, info)
        end

        attribute.AttachAttributes(evt, ATTRTAR_EVENT, owner, name, stack)

        return evt
    end

    local invokeEvent           = function(self, obj, ...)
        -- No check, as simple as it could be
        local delegate          = rawget(obj, _EventInfo[self][FLD_EVENT_FIELD])
        if delegate then return delegate:Invoke(obj, ...) end
    end

    local invokeStaticEvent     = function(self,...)
        local delegate          = _EventInfo[self][FLD_EVENT_DELEGATE]
        if delegate then return delegate:Invoke(...) end
    end

    -----------------------------------------------------------------------
    --                             prototype                             --
    -----------------------------------------------------------------------
    event                       = prototype {
        __tostring              = "event",
        __index                 = {
            --- Get the event delegate
            -- @static
            -- @method  Get
            -- @owner   event
            -- @param   target                      the target event
            -- @param   object                      the object if the event is not static
            -- @param   nocreation                  true if no need to generate the delegate if not existed
            -- @return  delegate                    the event's delegate
            ["Get"]             = function(self, obj, nocreation)
                local info      = _EventInfo[self]
                if info then
                    if info[FLD_EVENT_STATIC] then
                        local delegate      = info[FLD_EVENT_DELEGATE]
                        if not delegate and not nocreation then
                            local owner     = info[FLD_EVENT_OWNER]
                            local name      = info[FLD_EVENT_NAME]
                            delegate        = Delegate(owner, name)
                            info[FLD_EVENT_DELEGATE] = delegate

                            if info[FLD_EVENT_HANDLER] then
                                local handler   = info[FLD_EVENT_HANDLER]
                                delegate.OnChange = delegate.OnChange + function(self)
                                    return handler(self, owner, name)
                                end
                            end
                        end
                        return delegate
                    elseif type(obj) == "table" then
                        local delegate      = rawget(obj, info[FLD_EVENT_FIELD])
                        if not delegate or getmetatable(delegate) ~= Delegate then
                            if nocreation then return end

                            delegate        = Delegate(obj, info[FLD_EVENT_NAME])
                            rawset(obj, info[FLD_EVENT_FIELD], delegate)

                            if info[FLD_EVENT_HANDLER] then
                                local name      = info[FLD_EVENT_NAME]
                                local handler   = info[FLD_EVENT_HANDLER]
                                delegate.OnChange = delegate.OnChange + function(self)
                                    return handler(self, obj, name)
                                end
                            end
                        end
                        return delegate
                    end
                end
            end;

            --- Get the event change handler
            -- @static
            -- @method  GetEventChangeHandler
            -- @owner   event
            -- @param   target                      the target event
            -- @return  handler                     the event's change handler
            ["GetEventChangeHandler"] = function(self)
                local info      = _EventInfo[self]
                return info and info[FLD_EVENT_HANDLER] or false
            end;

            --- Whether the event's data is shared, always true
            -- @static
            -- @method  IsShareable
            -- @owner   event
            -- @param   target                      the target event
            -- @return  true
            ["IsShareable"]     = function() return true end;

            --- Whether the event is static
            -- @static
            -- @method  IsStatic
            -- @owner   event
            -- @param   target                      the target event
            -- @return  boolean                     true if the event is static
            ["IsStatic"]        = function(self)
                local info      = _EventInfo[self]
                return info and info[FLD_EVENT_STATIC] or false
            end;

            --- Invoke an event with parameters
            -- @static
            -- @method  Invoke
            -- @owner   event
            -- @format  (target[, object], ...)
            -- @param   target                      the target event
            -- @param   object                      the object if the event is not static
            -- @param   ...                         the parameters
            ["Invoke"]          = function(self, ...) return self:Invoke(...) end;

            --- Parse a string-boolean pair as the event's definition, the string is the event's name and true marks it as static
            -- @static
            -- @method  Parse
            -- @owner   event
            -- @format  (target, key, value[, stack])
            -- @param   target                      the target class or interface
            -- @param   key                         the key
            -- @param   value                       the value
            -- @param   stack                       the stack level
            -- @return  boolean                     true if key-value pair can be used as the event's definition
            ["Parse"]           = function(owner, key, value, stack)
                if type(key) == "string" and type(value) == "boolean" and owner and (interface.Validate(owner) or class.Validate(owner)) then
                    stack       = parsestack(stack) + 1
                    local evt   = genEvent(owner, key, value, stack)
                    interface.AddFeature(owner, key, evt, stack)
                    return true
                end
            end;

            --- Set delegate or a final handler to the event's delegate
            -- @static
            -- @method  Set
            -- @owner   event
            -- @format  (target, object, delegate[, stack])
            -- @param   target                      the target event
            -- @param   object                      the object if the event is not static
            -- @param   delegate                    the delegate used to copy or the final handler
            -- @param   stack                       the stack level
            ["Set"]             = function(self, obj, delegate, stack)
                local info      = _EventInfo[self]
                stack           = parsestack(stack) + 1
                if not info then error("Usage: event:Set(obj, delegate[, stack]) - the event is not valid", stack) end
                if type(obj) ~= "table" then error("Usage: event:Set(obj, delegate[, stack]) - the object is not valid", stack) end

                local odel      = self:Get(obj)
                if delegate == nil then
                    odel:SetFinalFunction(nil)
                elseif type(delegate) == "function" then
                    if attribute.HaveRegisteredAttributes() then
                        local name  = info[FLD_EVENT_NAME]
                        attribute.SaveAttributes(delegate, ATTRTAR_FUNCTION, stack)
                        local ret   = attribute.InitDefinition(delegate, ATTRTAR_FUNCTION, delegate, obj, name, stack)
                        if ret ~= delegate then
                            attribute.ToggleTarget(delegate, ret)
                            delegate   = ret
                        end
                        attribute.ApplyAttributes(delegate, ATTRTAR_FUNCTION, obj, name, stack)
                        attribute.AttachAttributes(delegate, ATTRTAR_FUNCTION, obj, name, stack)
                    end
                    odel:SetFinalFunction(ret)
                elseif getmetatable(delegate) == Delegate then
                    if delegate ~= odel then
                        delegate:CopyTo(odel)
                    end
                else
                    error("Usage: event:Set(obj, delegate[, stack]) - the delegate can only be function or object of System.Delegate", stack)
                end
            end;

            --- Set the event change handler
            -- @static
            -- @method  SetEventChangeHandler
            -- @owner   event
            -- @format  (target, handler[, stack])
            -- @param   target                      the target event
            -- @param   handler                     the event's change handler
            -- @param   stack                       the stack level
            ["SetEventChangeHandler"] = function(self, handler, stack)
                stack           = parsestack(stack) + 1
                if _EventInDefine[self] then
                    if type(handler) ~= "function" then error("Usage: event:SetEventChangeHandler(handler[, stack]) - the handler must be a function", stack) end
                    _EventInfo[self][FLD_EVENT_HANDLER] = handler
                else
                    error("Usage: event:SetEventChangeHandler(handler[, stack]) - the event's definition is finished", stack)
                end
            end;

            --- Set the event as static
            -- @static
            -- @method  SetStatic
            -- @owner   event
            -- @format  (target[, stack])
            -- @param   target                      the target event
            -- @param   stack                       the stack level
            ["SetStatic"]       = function(self, stack)
                if _EventInDefine[self] then
                    _EventInfo[self][FLD_EVENT_STATIC] = true
                else
                    error("Usage: event:SetStatic([stack]) - the event's definition is finished", parsestack(stack) + 1)
                end
            end;

            --- Whether the target is an event
            -- @static
            -- @method  Validate
            -- @owner   event
            -- @param   target                      the target event
            -- @return  target                      return the target if it's an event
            ["Validate"]        = function(self) return _EventInfo[self] and self or nil end;
        },
        __newindex              = readOnly,
        __call                  = function(self, ...)
            local visitor, env, name, definition, flag, stack = getFeatureParams(event, nil, ...)

            stack               = stack + 1

            if not name or name == "" then error([[Usage: event "name" - the name must be a string]], stack) end

            local owner = visitor and environment.GetNamespace(visitor)

            if owner and (interface.Validate(owner) or class.Validate(owner)) then
                local evt       = genEvent(owner, name, flag or false, stack)

                interface.AddFeature(owner, name, evt, stack)

                -- Save the event proxy to the visitor, so it can be called directly
                rawset(visitor, name, evt)

                return evt
            else
                error([[Usage: event "name" - the event can't be used here.]], stack)
            end
        end,
    }

    tevent                      = prototype {
        __tostring              = function(self)
            local info = _EventInfo[self]
            return "[event]" .. namespace.GetNamespaceName(info[FLD_EVENT_OWNER]) .. "." .. info[FLD_EVENT_NAME]
        end;
        __index                 = {
            ["Get"]             = event.Get;
            ["GetEventChangeHandler"] = event.GetEventChangeHandler;
            ["Invoke"]          = invokeEvent;
            ["IsShareable"]     = event.IsShareable;
            ["IsStatic"]        = event.IsStatic;
            ["Set"]             = event.Set;
            ["SetEventChangeHandler"] = event.SetEventChangeHandler;
            ["SetStatic"]       = event.SetStatic;
        },
        __newindex              = readOnly,
        __call                  = invokeEvent,
        __metatable             = event,
    }

    tsevent                     = prototype (tevent, {
        __index                 = {
            ["Invoke"]          = invokeStaticEvent;
        },
        __call                  = invokeStaticEvent;
        __metatable             = event,
    })

    -----------------------------------------------------------------------
    --                            registration                           --
    -----------------------------------------------------------------------
    interface.RegisterParser(event)
end

-------------------------------------------------------------------------------
-- The properties are object states, we can use the table fields to act as the
-- object states, but they lack the value validation, and we also can't track
-- the modification of those fields.
--
-- Like the event, the property is also a feature type of the interface and
-- class. The property system provide many mechanisms like get/set, value type
-- validation, value changed handler, value changed event, default value and
-- default value factory. Let's start with a simple example :
--
--              class "Person" (function(_ENV)
--                  property "Name" { type = String }
--                  property "Age"  { type = Number }
--              end)
--
--              -- If the class has no constructor, we can use the class to create the object based on a table
--              -- the table is called the init-table
--              o = Person{ Name = "Ann", Age = 10 }
--
--              print(o.Name)-- Ann
--              o.Name = 123 -- Error : the Name must be [String]
--
-- The **Person** class has two properties: *Name* and *Age*, the table after
-- `property "Name"` is the definition of the *Name* property, it contains a
-- *type* field that contains the property value's type, so when we assign a
-- number value to the *Name*, the operation is failed.
--
-- Like the **member** of the **struct**, we use table to give the property's
-- definition, the key is case ignored, here is a full list:
--
--      * get           the function used to get the property value from the
--              object like `get(obj)`, also you can set **false** to it, so
--              the property can't be read
--
--      * set           the function used to set the property value of the
--              object like `set(obj, value)`, also you can set **false** to
--              it, so the property can't be written
--
--      * getmethod     the string name used to specified the object method to
--              get the value like `obj[getmethod](obj)`
--
--      * setmethod     the string name used to specified the object method to
--              set the value like `obj[setmethod](obj, value)`
--
--      * field         the table field to save the property value, no use if
--              get/set specified, like the *Name* of the **Person**, since
--              there is no get/set or field specified, the system will auto
--              generate a field for it, it's recommended.
--
--      * type          the value's type, if the value is immutable, the type
--              validation can be turn off for release version, just turn on
--              **TYPE_VALIDATION_DISABLED** in the **PLOOP_PLATFORM_SETTINGS**
--
--      * default       the default value
--
--      * event         the event used to handle the property value changes,
--              if it's value is string, an event will be created:
--
--                  class "Person" (function(_ENV)
--                      property "Name" { type = String, event = "OnNameChanged" }
--                  end)
--
--                  o = Person { Name = "Ann" }
--
--                  function o:OnNameChanged(new, old, prop)
--                      print(("[%s] %s -> %s"):format(prop, old, new))
--                  end
--
--                  -- [Name] Ann -> Ammy
--                  o.Name = "Ammy"
--
--      * handler       the function used to handle the property value changes,
--               unlike the event, the handler is used to notify the class or
--              interface itself, normally this is used combine with **field**
--              (or auto-gen field), so the class or interface only need to act
--              based on the value changes :
--
--                  class "Person" (function(_ENV)
--                      property "Name" {
--                          type = String, default = "anonymous",
--                          handler = function(self, new, old, prop) print(("[%s] %s -> %s"):format(prop, old, new)) end
--                      }
--                  end)
--
--                  --[Name] anonymous -> Ann
--                  o = Person { Name = "Ann" }
--
--                  --[Name] Ann -> Ammy
--                  o.Name = "Ammy"
--
--      * static        true if the property is a static property
--
-- There is also a auto-binding mechanism for the property, if the definition
-- don't provide get/set, getmethod/setmethod and field, the system will check
-- the property owner's method(object method if non-static, static method if it
-- is static), if the property name is **name**:
--
--      * The *setname*, *Setname*, *SetName*, *setName* will be scanned, if it
--  existed, the method will be used as the **set** setting
--
--                  class "Person" (function(_ENV)
--                      function SetName(self, name)
--                          print("SetName", name)
--                      end
--
--                      property "Name" { type = String }
--                  end)
--
--                  -- SetName  Ann
--                  o = Person { Name = "Ann"}
--
--                  -- SetName  Ammy
--                  o.Name = "Ammy"
--
--      * The *getname*, *Getname*, *Isname*, *isname*, *getName*, *GetName*,
--  *IsName*, *isname* will be scanned, if it exsited, the method will be used
--  as the **get** setting
--
-- When the class or interface has overridden the property, they still can use
-- the super object access style to use the super's property :
--
--                  class "Person" (function(_ENV)
--                      property "Name" { event = "OnNameChanged" }
--                  end)
--
--                  class "Student" (function(_ENV)
--                      inherit "Person"
--
--                      property "Name" {
--                          Set = function(self, name)
--                              -- Use super property to save
--                              super[self].Name = name
--                          end,
--                          Get = function(self)
--                              -- Use super property to fetch
--                              return super[self].Name
--                          end,
--                      }
--                  end)
--
--                  o = Student()
--                  o.Name = "Test"
--                  print(o.Name)   -- Test
--
-- @prototype   property
-------------------------------------------------------------------------------
do
    -----------------------------------------------------------------------
    --                         attribute targets                         --
    -----------------------------------------------------------------------
    ATTRTAR_PROPERTY            = attribute.RegisterTargetType("Property")

    -----------------------------------------------------------------------
    --                         private constants                         --
    -----------------------------------------------------------------------
    -- MODIFIER
    local MOD_PROP_STATIC       = newflags(true)

    local MOD_PROP_SETCLONE     = newflags()
    local MOD_PROP_SETDEEPCL    = newflags()
    local MOD_PROP_SETRETAIN    = newflags()
    local MOD_PROP_SETWEAK      = newflags()

    local MOD_PROP_GETCLONE     = newflags()
    local MOD_PROP_GETDEEPCL    = newflags()

    -- PROPERTY FIELDS
    local FLD_PROP_MOD          =  0
    local FLD_PROP_RAWGET       =  1
    local FLD_PROP_RAWSET       =  2
    local FLD_PROP_NAME         =  3
    local FLD_PROP_OWNER        =  4
    local FLD_PROP_TYPE         =  5
    local FLD_PROP_VALID        =  6
    local FLD_PROP_FIELD        =  7
    local FLD_PROP_GET          =  8
    local FLD_PROP_SET          =  9
    local FLD_PROP_GETMETHOD    = 10
    local FLD_PROP_SETMETHOD    = 11
    local FLD_PROP_DEFAULT      = 12
    local FLD_PROP_DEFAULTFUNC  = 13
    local FLD_PROP_HANDLER      = 14
    local FLD_PROP_EVENT        = 15
    local FLD_PROP_STATIC       = 16

    -- FLAGS FOR PROPERTY BUILDING
    local FLG_PROPGET_DISABLE   = newflags(true)
    local FLG_PROPGET_DEFAULT   = newflags()
    local FLG_PROPGET_DEFTFUNC  = newflags()
    local FLG_PROPGET_GET       = newflags()
    local FLG_PROPGET_GETMETHOD = newflags()
    local FLG_PROPGET_FIELD     = newflags()
    local FLG_PROPGET_SETWEAK   = newflags()
    local FLG_PROPGET_SETFALSE  = newflags()
    local FLG_PROPGET_CLONE     = newflags()
    local FLG_PROPGET_DEEPCLONE = newflags()
    local FLG_PROPGET_STATIC    = newflags()

    local FLG_PROPSET_DISABLE   = newflags(true)
    local FLG_PROPSET_TYPE      = newflags()
    local FLG_PROPSET_CLONE     = newflags()
    local FLG_PROPSET_DEEPCLONE = newflags()
    local FLG_PROPSET_SET       = newflags()
    local FLG_PROPSET_SETMETHOD = newflags()
    local FLG_PROPSET_FIELD     = newflags()
    local FLG_PROPSET_DEFAULT   = newflags()
    local FLG_PROPSET_SETWEAK   = newflags()
    local FLG_PROPSET_RETAIN    = newflags()
    local FLG_PROPSET_SIMPDEFT  = newflags()
    local FLG_PROPSET_HANDLER   = newflags()
    local FLG_PROPSET_EVENT     = newflags()
    local FLG_PROPSET_STATIC    = newflags()

    local FLD_PROP_META         = "__PLOOP_PROPERTY_META"
    local FLD_PROP_OBJ_WEAK     = "__PLOOP_PROPERTY_WEAK"

    -----------------------------------------------------------------------
    --                          private storage                          --
    -----------------------------------------------------------------------
    local _PropertyInfo         = PLOOP_PLATFORM_SETTINGS.UNSAFE_MODE
                                    and setmetatable({}, {__index = function(_, c) return type(c) == "table" and rawget(c, FLD_PROP_META) or nil end})
                                    or  newStorage(WEAK_KEY)

    local _PropertyInDefine     = newStorage(WEAK_KEY)

    local _PropGetMap           = {}
    local _PropSetMap           = {}

    local _PropGetPrefix        = { "get", "Get", "is", "Is" }
    local _PropSetPrefix        = { "set", "Set" }

    -----------------------------------------------------------------------
    --                          private helpers                          --
    -----------------------------------------------------------------------
    local savePropertyInfo      = PLOOP_PLATFORM_SETTINGS.UNSAFE_MODE
                                    and function(target, info) rawset(target, FLD_PROP_META, info) end
                                    or  function(target, info) _PropertyInfo = saveStorage(_PropertyInfo, target, info) end


    local genProperty           = function(owner, name, stack)
        local prop              = prototype.NewProxy(tproperty)
        local info              = {
            [FLD_PROP_NAME]     = name,
            [FLD_PROP_OWNER]    = owner,
        }

        savePropertyInfo(prop, info)

        _PropertyInDefine       = saveStorage(_PropertyInDefine, prop, true)

        attribute.SaveAttributes(prop, ATTRTAR_PROPERTY, stack + 1)

        local super             = interface.GetSuperFeature(owner, name)
        if super and property.Validate(super) then attribute.InheritAttributes(prop, ATTRTAR_PROPERTY, super) end

        return prop
    end

    local genPropertyGet        = function (info)
        local token         = 0
        local usename       = false
        local upval         = _Cache()

        if info[FLD_PROP_GET] == false or (info[FLD_PROP_GET] == nil and info[FLD_PROP_GETMETHOD] == nil and info[FLD_PROP_FIELD] == nil and info[FLD_PROP_DEFAULTFUNC] == nil and info[FLD_PROP_DEFAULT] == nil) then
            token           = turnOnFlags(FLG_PROPGET_DISABLE, token)
            usename         = true
        else
            if info[FLD_PROP_DEFAULTFUNC] then
                token       = turnOnFlags(FLG_PROPGET_DEFTFUNC, token)
                tinsert(upval, info[FLD_PROP_DEFAULTFUNC])
                if info[FLD_PROP_SET] == false then
                    token   = turnOnFlags(FLG_PROPGET_SETFALSE, token)
                else
                    usename = true
                end
            elseif info[FLD_PROP_DEFAULT] ~= nil then
                token       = turnOnFlags(FLG_PROPGET_DEFAULT, token)
                tinsert(upval, info[FLD_PROP_DEFAULT])
            end

            if validateFlags(MOD_PROP_SETWEAK, info[FLD_PROP_MOD]) then
                token       = turnOnFlags(FLG_PROPGET_SETWEAK, token)
            end

            if validateFlags(MOD_PROP_STATIC, info[FLD_PROP_MOD]) then
                token       = turnOnFlags(FLG_PROPGET_STATIC, token)
                if validateFlags(FLG_PROPGET_SETWEAK, token) then
                    tinsert(upval, info[FLD_PROP_STATIC])
                else
                    tinsert(upval, info)
                end
            end

            if info[FLD_PROP_GET] then
                token       = turnOnFlags(FLG_PROPGET_GET, token)
                tinsert(upval, info[FLD_PROP_GET])
            elseif info[FLD_PROP_GETMETHOD] then
                token       = turnOnFlags(FLG_PROPGET_GETMETHOD, token)
                tinsert(upval, info[FLD_PROP_GETMETHOD])
            elseif info[FLD_PROP_FIELD] ~= nil then
                token       = turnOnFlags(FLG_PROPGET_FIELD, token)
                tinsert(upval, info[FLD_PROP_FIELD])
            end

            if validateFlags(MOD_PROP_GETCLONE, info[FLD_PROP_MOD]) then
                token       = turnOnFlags(FLG_PROPGET_CLONE, token)
                if validateFlags(MOD_PROP_GETDEEPCL, info[FLD_PROP_MOD]) then
                    token   = turnOnFlags(FLG_PROPGET_DEEPCLONE, token)
                end
            end
        end

        if usename then tinsert(upval, info[FLD_PROP_NAME]) end

        -- Building
        if not _PropGetMap[token] then
            local head      = _Cache()
            local body      = _Cache()
            local apis      = _Cache()

            tinsert(body, "")                       -- remain for shareable variables
            tinsert(body, "return function(%s)")    -- remain for special variables
            tinsert(body, [[return function(_, self)]])

            if validateFlags(FLG_PROPGET_DISABLE, token) then
                uinsert(apis, "error")
                uinsert(apis, "strformat")
                tinsert(body, [[error(strformat("the %s can't be read", name),2)]])
            else
                if validateFlags(FLG_PROPGET_DEFTFUNC, token) then
                    tinsert(head, "defaultFunc")
                elseif validateFlags(FLG_PROPGET_DEFAULT, token) then
                    tinsert(head, "default")
                end

                if validateFlags(FLG_PROPGET_STATIC, token) then
                    uinsert(apis, "fakefunc")
                    tinsert(head, "storage")
                end

                tinsert(body, [[local value]])

                if validateFlags(FLG_PROPGET_GET, token) then
                    tinsert(head, "get")
                    tinsert(body, [[value = get(self)]])
                elseif validateFlags(FLG_PROPGET_GETMETHOD, token) then
                    -- won't be static
                    tinsert(head, "getMethod")
                    tinsert(body, [[value = self[getMethod](self)]])
                elseif validateFlags(FLG_PROPGET_FIELD, token) then
                    tinsert(head, "field")
                    if validateFlags(FLG_PROPGET_STATIC, token) then
                        if validateFlags(FLG_PROPGET_SETWEAK, token) then
                            tinsert(body, [[value = storage[0] ]])
                        else
                            tinsert(body, [[value = storage[]] .. FLD_PROP_STATIC .. [[] ]])
                        end
                        tinsert(body, [[if value == fakefunc then value = nil end]])
                    else
                        uinsert(apis, "rawget")
                        if validateFlags(FLG_PROPGET_SETWEAK, token) then
                            tinsert(body, [[
                                value = rawget(self, "]] .. __PLOOP_PROPERTY_WEAK .. [[")
                                if type(value) == "table" then value = value[field] else value = nil end
                            ]])
                        else
                            tinsert(body, [[value = rawget(self, field)]])
                        end
                    end
                end

                -- Nil Handler
                if validateFlags(FLG_PROPGET_DEFTFUNC, token) or validateFlags(FLG_PROPGET_DEFAULT, token) then
                    tinsert(body, [[if value == nil then]])

                    if validateFlags(FLG_PROPGET_DEFTFUNC, token) then
                        tinsert(body, [[value = defaultFunc(self)]])
                        tinsert(body, [[if value ~= nil then]])

                        if validateFlags(FLG_PROPGET_STATIC, token) then
                            if validateFlags(FLG_PROPGET_SETFALSE, token) then
                                if validateFlags(FLG_PROPGET_SETWEAK, token) then
                                    tinsert(body, [[storage[0] = value]])
                                else
                                    tinsert(body, [[storage[]] .. FLD_PROP_STATIC .. [[] = value]])
                                end
                            else
                                tinsert(body, [[self[name]=value]])
                            end
                        else
                            if validateFlags(FLG_PROPGET_SETFALSE, token) then
                                uinsert(apis, "rawset")
                                if validateFlags(FLG_PROPGET_SETWEAK, token) then
                                    uinsert(apis, "rawget")
                                    uinsert(apis, "type")
                                    uinsert(apis, "setmetatable")
                                    uinsert(apis, "WEAK_VALUE")
                                    tinsert(body, [[
                                        local container = rawget(self, "]] .. __PLOOP_PROPERTY_WEAK .. [[")
                                        if type(container) ~= "table" then
                                            container   = setmetatable({}, WEAK_VALUE)
                                            rawset(self, "]] .. __PLOOP_PROPERTY_WEAK .. [[", container)
                                        end
                                        container[field] = value
                                    ]])
                                else
                                    tinsert(body, [[rawset(self, field, value)]])
                                end
                            else
                                tinsert(body, [[self[name]=value]])
                            end
                        end

                        tinsert(body, [[end]])
                    elseif validateFlags(FLG_PROPGET_DEFAULT, token) then
                        tinsert(body, [[value = default]])
                    end

                    tinsert(body, [[end]])
                end

                -- Clone
                if validateFlags(FLG_PROPGET_CLONE, token) then
                    uinsert(apis, "clone")
                    if validateFlags(FLG_PROPGET_DEEPCLONE) then
                        tinsert(body, [[value = clone(value, true, true)]])
                    else
                        tinsert(body, [[value = clone(value)]])
                    end
                end

                tinsert(body, [[return value]])
            end
            tinsert(body, [[end]])
            tinsert(body, [[end]])

            if usename then tinsert(head, "name") end

            if #apis > 0 then
                local declare   = tblconcat(apis, ", ")
                body[1]         = strformat("local %s = %s", declare, declare)
            end

            body[2]             = strformat(body[2], #head > 0 and tblconcat(head, ", ") or "")

            _PropGetMap[token]  = loadSnippet(tblconcat(body, "\n"), "Property_Get_" .. token)()

            if #head == 0 then
                _PropGetMap[token]  = _PropGetMap[token]()
            end

            _Cache(head)
            _Cache(body)
            _Cache(apis)
        end

        if #upval > 0 then
            info[FLD_PROP_RAWGET]   = _PropGetMap[token](unpack(upval))
        else
            info[FLD_PROP_RAWGET]   = _PropGetMap[token]
        end

        _Cache(upval)
    end

    local genPropertySet        = function (info)
        local token             = 0
        local usename           = false
        local upval             = _Cache()

        -- Calc the token
        if info[FLD_PROP_SET] == false or (info[FLD_PROP_SET] == nil and info[FLD_PROP_SETMETHOD] == nil and info[FLD_PROP_FIELD] == nil) then
            token               = turnOnFlags(FLG_PROPSET_DISABLE, token)
            usename             = true
        else
            if info[FLD_PROP_TYPE] and not (PLOOP_PLATFORM_SETTINGS.TYPE_VALIDATION_DISABLED and getobjectvalue(info[FLD_PROP_TYPE], "IsImmutable")) then
                token           = turnOnFlags(FLG_PROPSET_TYPE, token)
                tinsert(upval, info[FLD_PROP_VALID])
                tinsert(upval, info[FLD_PROP_TYPE])
                usename         = true
            end

            if validateFlags(MOD_PROP_SETCLONE, info[FLD_PROP_MOD]) then
                token           = turnOnFlags(FLG_PROPSET_CLONE, token)
                if validateFlags(MOD_PROP_SETDEEPCL, info[FLD_PROP_MOD]) then
                    token       = turnOnFlags(FLG_PROPSET_DEEPCLONE, token)
                end
            end

            if validateFlags(MOD_PROP_SETWEAK, info[FLD_PROP_MOD]) then
                token = turnOnFlags(FLG_PROPSET_SETWEAK, token)
            end

            if validateFlags(MOD_PROP_STATIC, info[FLD_PROP_MOD]) then
                token = turnOnFlags(FLG_PROPSET_STATIC, token)
                if validateFlags(FLG_PROPSET_SETWEAK, token) then
                    tinsert(upval, info[FLD_PROP_STATIC])
                else
                    tinsert(upval, info)
                end
            end

            if info[FLD_PROP_SET] then
                token = turnOnFlags(FLG_PROPSET_SET, token)
                tinsert(upval, info[FLD_PROP_SET])
            elseif info[FLD_PROP_SETMETHOD] and not validateFlags(MOD_PROP_STATIC, info[FLD_PROP_MOD]) then
                token = turnOnFlags(FLG_PROPSET_SETMETHOD, token)
                tinsert(upval, info[FLD_PROP_SETMETHOD])
            elseif info[FLD_PROP_FIELD] then
                token = turnOnFlags(FLG_PROPSET_FIELD, token)
                tinsert(upval, info[FLD_PROP_FIELD])

                if info[FLD_PROP_DEFAULT] ~= nil then
                    token = turnOnFlags(FLG_PROPSET_DEFAULT, token)
                    tinsert(upval, info[FLD_PROP_DEFAULT])

                    if type(info[FLD_PROP_DEFAULT]) ~= "table" then
                        token = turnOnFlags(FLG_PROPSET_SIMPDEFT, token)
                    end
                end

                if validateFlags(MOD_PROP_SETRETAIN, info[FLD_PROP_MOD]) then
                    token = turnOnFlags(FLG_PROPSET_RETAIN, token)
                end

                if info[FLD_PROP_HANDLER] then
                    token = turnOnFlags(FLG_PROPSET_HANDLER, token)
                    tinsert(upval, info[FLD_PROP_HANDLER])
                    usename = true
                end

                if info[FLD_PROP_EVENT] then
                    token = turnOnFlags(FLG_PROPSET_EVENT, token)
                    tinsert(upval, info[FLD_PROP_EVENT])
                    usename = true
                end
            end
        end

        if usename then tinsert(upval, info[FLD_PROP_NAME]) end

        -- Building
        if not _PropSetMap[token] then
            local head      = _Cache()
            local body      = _Cache()
            local apis      = _Cache()

            tinsert(body, "")                       -- remain for shareable variables
            tinsert(body, "return function(%s)")    -- remain for special variables

            tinsert(body, [[return function(_, self, value)]])

            if validateFlags(FLG_PROPSET_DISABLE, token) then
                uinsert(apis, "error")
                uinsert(apis, "strformat")
                tinsert(body, [[error(strformat("the %s can't be set", name), 3)]])
            else
                if validateFlags(FLG_PROPSET_TYPE, token) or validateFlags(FLG_PROPSET_CLONE, token) then
                    tinsert(body, [[
                        if value ~= nil then
                    ]])
                    if validateFlags(FLG_PROPSET_TYPE, token) then
                        uinsert(apis, "error")
                        uinsert(apis, "type")
                        uinsert(apis, "strgsub")
                        tinsert(head, "valid")
                        tinsert(head, "vtype")
                        tinsert(body, [[
                            local ret, msg = valid(vtype, value)
                            if msg then error(strgsub(type(msg) == "string" and msg or "the %s is not valid", "%%s%.?", name), 3) end
                            value = ret
                        ]])
                    end

                    if validateFlags(FLG_PROPSET_CLONE, token) then
                        uinsert(apis, "clone")
                        if validateFlags(FLG_PROPSET_DEEPCLONE, token) then
                            tinsert(body, [[value = clone(value, true, true)]])
                        else
                            tinsert(body, [[value = clone(value)]])
                        end
                    end

                    tinsert(body, [[
                        end
                    ]])
                end
                if validateFlags(FLG_PROPSET_STATIC, token) then
                    uinsert(apis, "fakefunc")
                    tinsert(head, "storage")
                end

                if validateFlags(FLG_PROPSET_SET, token) then
                    tinsert(head, "set")
                    tinsert(body, [[return set(self, value)]])
                elseif validateFlags(FLG_PROPSET_SETMETHOD, token) then
                    tinsert(head, "setmethod")
                    tinsert(body, [[return self[setmethod](self, value)]])
                elseif validateFlags(FLG_PROPSET_FIELD, token) then
                    tinsert(head, "field")

                    local useold = validateFlags(FLG_PROPSET_DEFAULT, token) or validateFlags(FLG_PROPSET_RETAIN, token) or validateFlags(FLG_PROPSET_HANDLER, token) or validateFlags(FLG_PROPSET_EVENT, token)

                    if useold then
                        if validateFlags(FLG_PROPSET_STATIC, token) then
                            if validateFlags(FLG_PROPSET_SETWEAK, token) then
                                tinsert(body, [[local old = storage[0] ]])
                            else
                                tinsert(body, [[local old = storage[]] .. FLD_PROP_STATIC .. [[] ]])
                            end

                            tinsert(body, [[if old == fakefunc then old = nil end]])
                        else
                            uinsert(apis, "rawset")
                            uinsert(apis, "rawget")
                            if validateFlags(FLG_PROPSET_SETWEAK, token) then
                                uinsert(apis, "type")
                                uinsert(apis, "setmetatable")
                                uinsert(apis, "WEAK_VALUE")
                                tinsert(body, [[
                                    local container = rawget(self, "]] .. __PLOOP_PROPERTY_WEAK .. [[")
                                    if type(container) ~= "table" then
                                        container   = setmetatable({}, WEAK_VALUE)
                                        rawset(self, "]] .. __PLOOP_PROPERTY_WEAK .. [[", container)
                                    end
                                    local old = container[field]
                                ]])
                            else
                                tinsert(body, [[local old = rawget(self, field)]])
                            end
                        end

                        if validateFlags(FLG_PROPSET_DEFAULT, token) then
                            tinsert(head, "default")
                            tinsert(body, [[if (old == default or old == nil) and (value == nil or value == default) then return end]])
                        end

                        tinsert(body, [[if old == value then return end]])
                    end

                    if validateFlags(FLG_PROPSET_STATIC, token) then
                        if validateFlags(FLG_PROPSET_SETWEAK, token) then
                            tinsert(body, [[storage[0] = value == nil and fakefunc or value ]])
                        else
                            tinsert(body, [[storage[]] .. FLD_PROP_STATIC .. [[] = value == nil and fakefunc or value ]])
                        end
                    else
                        if validateFlags(FLG_PROPSET_SETWEAK, token) then
                            if useold then
                                tinsert(body, [[container[field] = value)]])
                            else
                                tinsert(body, [[
                                    local container = rawget(self, "]] .. __PLOOP_PROPERTY_WEAK .. [[")
                                    if type(container) ~= "table" then
                                        container   = setmetatable({}, WEAK_VALUE)
                                        rawset(self, "]] .. __PLOOP_PROPERTY_WEAK .. [[", container)
                                    end
                                    container[field] = value
                                ]])
                            end
                        else
                            tinsert(body, [[rawset(self, field, value)]])
                        end
                    end

                    if validateFlags(FLG_PROPSET_DEFAULT, token) and validateFlags(FLG_PROPSET_SIMPDEFT, token) then
                        tinsert(body, [[if old == nil then old = default end]])
                        tinsert(body, [[if value == nil then value = default end]])
                    end

                    if validateFlags(FLG_PROPSET_HANDLER, token) then
                        tinsert(head, "handler")
                        tinsert(body, [[handler(self, value, old, name)]])
                    end

                    if validateFlags(FLG_PROPSET_EVENT, token) then
                        tinsert(head, "evt")
                        tinsert(body, [[evt(self, value, old, name)]])
                    end

                    if validateFlags(FLG_PROPSET_RETAIN, token) then
                        uinsert(apis, "pcall")
                        uinsert(apis, "diposeObj")
                        if validateFlags(FLG_PROPSET_DEFAULT, token) then
                            tinsert(body, [[if old and old ~= default then pcall(diposeObj, old) end]])
                        else
                            tinsert(body, [[if old then pcall(diposeObj, old) end]])
                        end
                    end
                end
            end

            tinsert(body, [[end]])
            tinsert(body, [[end]])

            if usename then tinsert(head, "name") end

            if #apis > 0 then
                local declare   = tblconcat(apis, ", ")
                body[1]         = strformat("local %s = %s", declare, declare)
            end

            body[2]             = strformat(body[2], #head > 0 and tblconcat(head, ", ") or "")

            _PropSetMap[token]  = loadSnippet(tblconcat(body, "\n"), "Property_Set_" .. token)()

            if #head == 0 then
                _PropSetMap[token]  = _PropSetMap[token]()
            end

            _Cache(head)
            _Cache(body)
            _Cache(apis)
        end

        if #upval > 0 then
            info[FLD_PROP_RAWSET]   = _PropSetMap[token](unpack(upval))
        else
            info[FLD_PROP_RAWSET]   = _PropSetMap[token]
        end

        _Cache(upval)
    end

    -----------------------------------------------------------------------
    --                             prototype                             --
    -----------------------------------------------------------------------
    property                    = prototype {
        __index                 = {
            --- Get the property accessor, the accessor will be used by object to get/set value instead of the property itself
            -- @static
            -- @method  GetAccessor
            -- @owner   property
            -- @param   target                      the target property
            -- @return  accessor                    A table like { Get = func, Set = func }
            ["GetAccessor"]     = function(self)
                local info      = _PropertyInfo[self]
                if not info then return end

                if not info[FLD_PROP_RAWGET] then
                    local name      = info[FLD_PROP_NAME]
                    local uname     = name:gsub("^%a", strupper)
                    local owner     = info[FLD_PROP_OWNER]
                    local isstatic  = validateFlags(MOD_PROP_STATIC, info[FLD_PROP_MOD])

                    -- Check get method
                    if info[FLD_PROP_GETMETHOD] then
                        local mtd, st   = interface.GetMethod(owner, info[FLD_PROP_GETMETHOD])
                        if mtd and isstatic == st then
                            if isstatic then
                                info[FLD_PROP_GETMETHOD]    = nil
                                info[FLD_PROP_GET]          = mtd
                            end
                        else
                            Warn("The %s don't have a %smethod named %q for property %q's get method", tostring(owner), isstatic and "static " or "", info[FLD_PROP_GETMETHOD], name)
                            info[FLD_PROP_GETMETHOD]        = nil
                        end
                    end

                    -- Check set method
                    if info[FLD_PROP_SETMETHOD] then
                        local mtd, st   = interface.GetMethod(owner, info[FLD_PROP_SETMETHOD])
                        if mtd and isstatic == st then
                            if isstatic then
                                info[FLD_PROP_SETMETHOD]    = nil
                                info[FLD_PROP_SET]          = mtd
                            end
                        else
                            Warn("The %s don't have a %smethod named %q for property %q's set method", tostring(owner), isstatic and "static " or "", info[FLD_PROP_SETMETHOD], name)
                            info[FLD_PROP_SETMETHOD]        = nil
                        end
                    end

                    -- Auto-gen get (only check GetXXX, getXXX, IsXXX, isXXX for simple)
                    if info[FLD_PROP_GET] == true or (info[FLD_PROP_GET] == nil and info[FLD_PROP_GETMETHOD] == nil and info[FLD_PROP_FIELD] == nil) then
                        info[FLD_PROP_GET]  = nil

                        for _, prefix in ipairs, _PropGetPrefix, 0 do
                            local mtd, st   = interface.GetMethod(owner, prefix .. name)
                            if mtd and isstatic == st then
                                info[FLD_PROP_GET] = mtd
                                Debug("The %s's property %q use method named %q as get method", tostring(owner), name, prefix .. name)
                                break
                            end

                            if uname ~= name then
                                mtd, st     = interface.GetMethod(owner, prefix .. uname)
                                if mtd and isstatic == st then
                                    info[FLD_PROP_GET] = mtd
                                    Debug("The %s's property %q use method named %q as get method", tostring(owner), name, prefix .. uname)
                                    break
                                end
                            end
                        end
                    end

                    -- Auto-gen set (only check SetXXX, setXXX)
                    if info[FLD_PROP_SET] == true or (info[FLD_PROP_SET] == nil and info[FLD_PROP_SETMETHOD] == nil and info[FLD_PROP_FIELD] == nil) then
                        info[FLD_PROP_SET]  = nil

                        for _, prefix in ipairs, _PropSetPrefix, 0 do
                            local mtd, st   = interface.GetMethod(owner, prefix .. name)
                            if mtd and isstatic == st then
                                info[FLD_PROP_SET]  = mtd
                                Debug("The %s's property %q use method named %q as set method", tostring(owner), name, prefix .. name)
                                break
                            end

                            if uname ~= name then
                                local mtd, st   = interface.GetMethod(owner, prefix .. uname)
                                if mtd and isstatic == st then
                                    info[FLD_PROP_SET]  = mtd
                                    Debug("The %s's property %q use method named %q as set method", tostring(owner), name, prefix .. uname)
                                    break
                                end
                            end
                        end
                    end

                    -- Check the handler
                    if type(info[FLD_PROP_HANDLER]) == "string" then
                        local mtd, st   = interface.GetMethod(owner, info[FLD_PROP_HANDLER])
                        if mtd and isstatic == st then
                            info[FLD_PROP_HANDLER]  = mtd
                        else
                            Warn("The %s don't have a %smethod named %q for property %q's handler", tostring(owner), isstatic and "static " or "", info[FLD_PROP_HANDLER], name)
                            info[FLD_PROP_HANDLER]  = nil
                        end
                    end

                    -- Auto-gen field
                    if (info[FLD_PROP_SET] == nil or (info[FLD_PROP_SET] == false and info[FLD_PROP_DEFAULTFUNC]))
                        and info[FLD_PROP_SETMETHOD] == nil
                        and info[FLD_PROP_GET] == nil and info[FLD_PROP_GETMETHOD] == nil then

                        if info[FLD_PROP_FIELD] == true then info[FLD_PROP_FIELD] = nil end

                        info[FLD_PROP_FIELD] = info[FLD_PROP_FIELD] or "_" .. namespace.GetNamespaceName(owner, true) .. "_" .. uname

                    end

                    -- Gen static value container
                    if isstatic then
                        -- Use fakefunc as nil object
                        if validateFlags(MOD_PROP_SETWEAK, info[FLD_PROP_MOD]) then
                            info[FLD_PROP_STATIC] = setmetatable({ [0] = fakefunc }, WEAK_VALUE)
                        else
                            info[FLD_PROP_STATIC] = fakefunc
                        end
                    end

                    -- Generate the get & set
                    genPropertyGet(info)
                    genPropertySet(info)
                end

                return { Get = info[FLD_PROP_RAWGET], Set = info[FLD_PROP_RAWSET] }
            end;

            --- Whether the property should return a clone copy of the value
            -- @static
            -- @method  IsGetClone
            -- @owner   property
            -- @param   target                      the target property
            -- @return  boolean                     true if should return a clone copy of the value
            ["IsGetClone"]      = function(self)
                local info      = _PropertyInfo[self]
                return info and validateFlags(MOD_PROP_GETCLONE, info[FLD_PROP_MOD]) or false
            end;

            --- Whether the property should return a deep clone copy of the value
            -- @static
            -- @method  IsGetDeepClone
            -- @owner   property
            -- @param   target                      the target property
            -- @return  boolean                     true if should return a deep clone copy of the value
            ["IsGetDeepClone"]  = function(self)
                local info      = _PropertyInfo[self]
                return info and validateFlags(MOD_PROP_GETDEEPCL, info[FLD_PROP_MOD]) or false
            end;

            --- Whether the property should save a clone copy to the value
            -- @static
            -- @method  IsSetClone
            -- @owner   property
            -- @param   target                      the target property
            -- @return  boolean                     true if should save a clone copy to the value
            ["IsSetClone"]      = function(self)
                local info      = _PropertyInfo[self]
                return info and validateFlags(MOD_PROP_SETCLONE, info[FLD_PROP_MOD]) or false
            end;

            --- Whether the property should save a deep clone copy to the value
            -- @static
            -- @method  IsSetDeepClone
            -- @owner   property
            -- @param   target                      the target property
            -- @return  boolean                     true if should save a deep clone copy to the value
            ["IsSetDeepClone"]  = function(self)
                local info      = _PropertyInfo[self]
                return info and validateFlags(MOD_PROP_SETDEEPCL, info[FLD_PROP_MOD]) or false
            end;

            --- Whether the property should dispose the old value
            -- @static
            -- @method  IsRetainObject
            -- @owner   property
            -- @param   target                      the target property
            -- @return  boolean                     true if should dispose the old value
            ["IsRetainObject"]  = function(self)
                local info      = _PropertyInfo[self]
                return info and validateFlags(MOD_PROP_SETRETAIN, info[FLD_PROP_MOD]) or false
            end;

            --- Whether the property data is shareable, always true
            -- @static
            -- @method  IsShareable
            -- @owner   property
            -- @param   target                      the target property
            -- @return  true
            ["IsShareable"]     = function(self) return true end;

            --- Whether the property is static
            -- @static
            -- @method  IsStatic
            -- @owner   property
            -- @param   target                      the target property
            -- @return  boolean                     true if the property is static
            ["IsStatic"]        = function(self)
                local info      = _PropertyInfo[self]
                return info and validateFlags(MOD_PROP_STATIC, info[FLD_PROP_MOD]) or false
            end;

            --- Whether the property value should kept in a weak table
            -- @static
            -- @method  IsWeak
            -- @owner   property
            -- @param   target                      the target property
            -- @return  boolean                     true if the property value should kept in a weak table
            ["IsWeak"]          = function(self)
                local info      = _PropertyInfo[self]
                return info and validateFlags(MOD_PROP_SETWEAK, info[FLD_PROP_MOD]) or false
            end;

            --- Set the property whether it should return a clone copy of the value
            -- @static
            -- @method  GetClone
            -- @owner   property
            -- @format  (target[, deep[, stack]])
            -- @param   target                      the target property
            -- @param   deep                        true if need deep clone
            -- @param   stack                       the stack level
            ["GetClone"]     = function(self, deep, stack)
                if _PropertyInDefine[self] then
                    local info  = _PropertyInfo[self]
                    info[FLD_PROP_MOD]  = turnOnFlags(MOD_PROP_GETCLONE, info[FLD_PROP_MOD])
                    if deep then info[FLD_PROP_MOD]  = turnOnFlags(MOD_PROP_GETDEEPCL, info[FLD_PROP_MOD]) end
                else
                    error("Usage: property:GetClone(deep, [stack]) - the property's definition is finished", parsestack(stack) + 1)
                end
            end;

            --- Parse a string-[table|type] pair as the property's definition, the string is the property's name and the value should be a table or a valid type
            -- @static
            -- @method  Parse
            -- @owner   property
            -- @format  (target, key, value[, stack])
            -- @param   target                      the target class or interface
            -- @param   key                         the key
            -- @param   value                       the value
            -- @param   stack                       the stack level
            -- @return  boolean                     true if key-value pair can be used as the property's definition
            ["Parse"]           = function(owner, key, value, stack)
                if type(key) == "string" and (getprototypemethod(value, "ValidateValue") or (type(value) == "table" and getmetatable(value) == nil)) and owner and (interface.Validate(owner) or class.Validate(owner)) then
                    stack       = parsestack(stack) + 1
                    if getprototypemethod(value, "ValidateValue") then value = { type = value } end
                    local prop  = genProperty(owner, key, stack)
                    prop(value, stack)
                    return true
                end
            end;

            --- Set the property whether it should save a clone copy of the value
            -- @static
            -- @method  SetClone
            -- @owner   property
            -- @format  (target[, deep[, stack]])
            -- @param   target                      the target property
            -- @param   deep                        true if need deep clone
            -- @param   stack                       the stack level
            ["SetClone"]     = function(self, deep, stack)
                if _PropertyInDefine[self] then
                    local info  = _PropertyInfo[self]
                    info[FLD_PROP_MOD]  = turnOnFlags(MOD_PROP_SETCLONE, info[FLD_PROP_MOD])
                    if deep then info[FLD_PROP_MOD]  = turnOnFlags(MOD_PROP_SETDEEPCL, info[FLD_PROP_MOD]) end
                else
                    error("Usage: property:SetClone(deep, [stack]) - the property's definition is finished", parsestack(stack) + 1)
                end
            end;

            --- Set the property whether it should dispose the old value
            -- @static
            -- @method  SetRetainObject
            -- @owner   property
            -- @format  (target[, stack]])
            -- @param   target                      the target property
            -- @param   stack                       the stack level
            ["SetRetainObject"] = function(self, stack)
                if _PropertyInDefine[self] then
                    local info  = _PropertyInfo[self]
                    info[FLD_PROP_MOD]  = turnOnFlags(MOD_PROP_SETRETAIN, info[FLD_PROP_MOD])
                else
                    error("Usage: property:SetRetainObject([stack]) - the property's definition is finished", parsestack(stack) + 1)
                end
            end;

            --- Mark the property as static
            -- @static
            -- @method  SetStatic
            -- @owner   property
            -- @format  (target[, stack]])
            -- @param   target                      the target property
            -- @param   stack                       the stack level
            ["SetStatic"]       = function(self, stack)
                if _PropertyInDefine[self] then
                    local info  = _PropertyInfo[self]
                    info[FLD_PROP_MOD]  = turnOnFlags(MOD_PROP_STATIC, info[FLD_PROP_MOD])
                else
                    error("Usage: property:SetStatic([stack]) - the property's definition is finished", parsestack(stack) + 1)
                end
            end;

            --- Mark the property so its value should be kept in a weak table
            -- @static
            -- @method  SetWeak
            -- @owner   property
            -- @format  (target[, stack]])
            -- @param   target                      the target property
            -- @param   stack                       the stack level
            ["SetWeak"]         = function(self, stack)
                if _PropertyInDefine[self] then
                    local info  = _PropertyInfo[self]
                    info[FLD_PROP_MOD]  = turnOnFlags(MOD_PROP_SETWEAK, info[FLD_PROP_MOD])
                else
                    error("Usage: property:SetWeak([stack]) - the property's definition is finished", parsestack(stack) + 1)
                end
            end;

            --- Wether the value is a property
            -- @static
            -- @method  Validate
            -- @owner   property
            -- @param   target                      the target property
            -- @param   target                      return the taret is it's a property
            ["Validate"]        = function(self) return _PropertyInfo[self] and self or nil end;
        },
        __call                  = function(self, ...)
            local visitor, env, name, definition, flag, stack = getFeatureParams(property, nil, ...)

            stack               = stack + 1

            if not name or name == "" then error([[Usage: property "name" { ... } - the name must be a string]], stack) end

            local owner = visitor and environment.GetNamespace(visitor)

            if owner and (interface.Validate(owner) or class.Validate(owner)) then
                local prop      = genProperty(owner, name, stack)
                return prop
            else
                error([[Usage: property "name" - the property can't be used here.]], stack)
            end
        end,
    }

    tproperty                   = prototype {
        __tostring              = function(self)
            local info = _PropertyInfo[self]
            return "[property]" .. namespace.GetNamespaceName(info[FLD_PROP_OWNER]) .. "." .. info[FLD_PROP_NAME]
        end;
        __index                 = {
            ["GetAccessor"]     = property.GetAccessor;
            ["IsGetClone"]      = property.IsGetClone;
            ["IsGetDeepClone"]  = property.IsGetDeepClone;
            ["IsSetClone"]      = property.IsSetClone;
            ["IsSetDeepClone"]  = property.IsSetDeepClone;
            ["IsRetainObject"]  = property.IsRetainObject;
            ["IsShareable"]     = property.IsShareable;
            ["IsStatic"]        = property.IsStatic;
            ["IsWeak"]          = property.IsWeak;
            ["GetClone"]        = property.GetClone;
            ["SetClone"]        = property.SetClone;
            ["SetRetainObject"] = property.SetRetainObject;
            ["SetStatic"]       = property.SetStatic;
            ["SetWeak"]         = property.SetWeak;
        },
        __call                  = function(self, definition, stack)
            stack               = parsestack(stack) + 1

            if type(definition) ~= "table" then error([[Usage: property "name" { definition } - the definition part must be a table]], stack) end
            if not _PropertyInDefine[self] then error([[Usage: property "name" { definition } - the property's definition is finished]], stack) end

            local info          = _PropertyInfo[self]
            local owner         = info[FLD_PROP_OWNER]
            local name          = info[FLD_PROP_NAME]

            attribute.InitDefinition(self, ATTRTAR_PROPERTY, definition, owner, name, stack)

            -- Parse the definition
            for k, v in pairs, definition do
                if type(k) == "string" then
                    k   = strlower(k)
                    local tval  = type(v)

                    if k == "get" then
                        if tval == "function" or tval == "boolean" then
                            info[FLD_PROP_GET] = v
                        elseif tval == "string" then
                            info[FLD_PROP_GETMETHOD] = v
                        else
                            error([[Usage: property "name" { get = ... } - the "get" must be function, string or boolean]], stack)
                        end
                    elseif k == "set" then
                        if tval == "function" or tval == "boolean" then
                            info[FLD_PROP_SET] = v
                        elseif tval == "string" then
                            info[FLD_PROP_SETMETHOD] = v
                        else
                            error([[Usage: property "name" { set = ... } - the "set" must be function, string or boolean]], stack)
                        end
                    elseif k == "getmethod" then
                        if tval == "string" then
                            info[FLD_PROP_GETMETHOD] = v
                        else
                            error([[Usage: property "name" { getmethod = ... } - the "get" must be string]], stack)
                        end
                    elseif k == "setmethod" then
                        if tval == "string" then
                            info[FLD_PROP_SETMETHOD] = v
                        else
                            error([[Usage: property "name" { setmethod = ... } - the "get" must be string]], stack)
                        end
                    elseif k == "field" then
                        if v ~= name then
                            info[FLD_PROP_FIELD] = v ~= name and v or nil
                        else
                            error([[Usage: property "name" { field = ... } - the field can't be the same with the property name]], stack)
                        end
                    elseif k == "type" then
                        local tpValid   = getprototypemethod(v, "ValidateValue")
                        if tpValid then
                            info[FLD_PROP_TYPE]  = v
                            info[FLD_PROP_VALID] = tpValid
                        else
                            error([[Usage: property "name" { type = ... } - the type is not valid]], stack)
                        end
                    elseif k == "default" then
                        if type(v) == "function" then
                            info[FLD_PROP_DEFAULTFUNC] = v
                        else
                            info[FLD_PROP_DEFAULT] = v
                        end
                    elseif k == "event" then
                        if tval == "string" or event.Validate(v) then
                            info[FLD_PROP_EVENT] = v
                        else
                            error([[Usage: property "name" { event = ... } - the event is not valid]], stack)
                        end
                    elseif k == "handler" then
                        if tval == "string" or tval == "function" then
                            info[FLD_PROP_HANDLER] = v
                        else
                            error([[Usage: property "name" { handler = ... } - the handler must be function or string]], stack)
                        end
                    elseif k == "isstatic" or k == "static" then
                        if v then
                            info[FLD_PROP_MOD]  = turnOnFlags(MOD_PROP_STATIC, info[FLD_PROP_MOD])
                        end
                    end
                end
            end

            -- Check Default
            if info[FLD_PROP_DEFAULT] ~= nil and info[FLD_PROP_TYPE] then
                local ret, msg = info[FLD_PROP_VALID](info[FLD_PROP_TYPE], info[FLD_PROP_DEFAULT])
                if not msg then
                    info[FLD_PROP_DEFAULT] = ret
                else
                    error([[Usage: property "name" { type = ...,  default = ... } - the default don't match the type setting]], stack)
                end
            elseif info[FLD_PROP_DEFAULT] == nil and info[FLD_PROP_TYPE] then
                info[FLD_PROP_DEFAULT] = getobjectvalue(info[FLD_PROP_TYPE], "GetDefault")
            end

            -- Clear conflict settings
            if info[FLD_PROP_GET] then info[FLD_PROP_GETMETHOD] = nil end
            if info[FLD_PROP_SET] then info[FLD_PROP_SETMETHOD] = nil end

            attribute.ApplyAttributes(self, ATTRTAR_PROPERTY, owner, name, stack)

            _PropertyInDefine  = saveStorage(_PropertyInDefine, self, nil)

            attribute.AttachAttributes(self, ATTRTAR_PROPERTY, owner, name, stack)

            -- Check the event
            if type(info[FLD_PROP_EVENT]) == "string" then
                local ename     = info[FLD_PROP_EVENT]
                local evt       = interface.GetFeature(owner, ename)

                if event.Validate(evt) then
                    if evt:IsStatic() == self:IsStatic() then
                        info[FLD_PROP_EVENT] = evt
                    elseif evt:IsStatic() then
                        error([[Usage: property "name" { event = ... } - the event is static]], stack)
                    else
                        error([[Usage: property "name" { event = ... } - the event is not static]], stack)
                    end
                elseif evt == nil then
                    -- Auto create the event
                    event.Parse(owner, ename, self:IsStatic() or false, stack)
                    info[FLD_PROP_EVENT] = interface.GetFeature(owner, ename)
                else
                    error([[Usage: property "name" { event = ... } - the event is not valid]], stack)
                end
            end

            interface.AddFeature(owner, name, self, stack)
        end,
        __newindex              = readOnly,
        __metatable             = property,
    }

    -----------------------------------------------------------------------
    --                            registration                           --
    -----------------------------------------------------------------------
    interface.RegisterParser(property)
end

-------------------------------------------------------------------------------
-- The exception system are used to throw the error with debug datas on will.
--
-- The functions contains the throw-exception action must be called within the
-- *pcall* function, Lua don't allow using table as error message for directly
-- call. A normal scenario is use the throw-exception style in the constructor
-- of the classes.
--
-- @keyword     throw
-------------------------------------------------------------------------------
do
    throw                       = function (exception)
        local visitor, env      = getFeatureParams(throw)

        if type(exception) == "string" or not class.IsSubType(getmetatable(exception), Exception) then
            exception = Exception(tostring(exception))
        end

        local stack             = exception.StackLevel + 1
        if exception.StackDataSaved then error(exception, stack) end

        exception.StackDataSaved= true

        if traceback then
            exception.StackTrace= traceback(exception.Message, stack)
        end

        local func

        if debuginfo then
            local info          = debuginfo(stack, "lSf")
            if info then
                exception.Source    = (info.short_src or "unknown") .. ":" .. (info.currentline or "?")
                func                = info.func
                exception.TargetSite= visitor and tostring(visitor)
            end
        end

        if exception.SaveVariables then
            if getlocal then
                local index         = 1
                local k, v          = getlocal(stack, index)
                local vars          = k and {}
                while k do
                    vars[k]     = v

                    index           = index + 1
                    k, v            = getlocal(stack, index)
                end
                if next(vars) then exception.LocalVariables = vars end
            end

            if getupvalue and func then
                local index         = 1
                local k, v          = getupvalue(func, index)
                local vars          = k and {}
                while k do
                    vars[k]         = v

                    index           = index + 1
                    k, v            = getupvalue(func, index)
                end
                if next(vars) then exception.Upvalues = vars end
            end
        end

        error(exception, stack)
    end
end

-------------------------------------------------------------------------------
--                           keyword installation                            --
-------------------------------------------------------------------------------
do
    -----------------------------------------------------------------------
    --                          global keyword                           --
    -----------------------------------------------------------------------
    environment.RegisterGlobalKeyword {
        namespace               = namespace,
        import                  = import,
        export                  = export,
        enum                    = enum,
        struct                  = struct,
        class                   = class,
        interface               = interface,
        throw                   = throw,
        currentenv              = currentenv,
    }

    -----------------------------------------------------------------------
    --                          struct keyword                           --
    -----------------------------------------------------------------------
    environment.RegisterContextKeyword(struct.GetDefinitionContext(), {
        member                  = member,
        array                   = array,
        endstruct               = rawget(_PLoopEnv, "endstruct"),
    })

    -----------------------------------------------------------------------
    --                         interface keyword                         --
    -----------------------------------------------------------------------
    environment.RegisterContextKeyword(interface.GetDefinitionContext(), {
        require                 = require,
        extend                  = extend,
        field                   = field,
        event                   = event,
        property                = property,
        endinterface            = rawget(_PLoopEnv, "endinterface"),
    })

    -----------------------------------------------------------------------
    --                           class keyword                           --
    -----------------------------------------------------------------------
    environment.RegisterContextKeyword(class.GetDefinitionContext(), {
        inherit                 = inherit,
        extend                  = extend,
        field                   = field,
        event                   = event,
        property                = property,
        endclass                = rawget(_PLoopEnv, "endclass"),
    })
end

-------------------------------------------------------------------------------
-- The **System** namespace contains fundamental prototypes, attributes, enums,
-- structs, interfaces and classes
--
-- @namespace   System
-------------------------------------------------------------------------------
do
    -----------------------------------------------------------------------
    --                          private storage                          --
    -----------------------------------------------------------------------
    local _LambdaCache          = newStorage(WEAK_VALUE)

    -----------------------------------------------------------------------
    --                          private helpers                          --
    -----------------------------------------------------------------------
    local getClassMeta          = class.GetMetaMethod

    local genBasicValidator     = function(tname)
        local msg               = "the %s must be " .. tname .. ", got "
        local type              = type
        return function(val, onlyvalid) local tval = type(val) return tval ~= tname and (onlyvalid or msg .. tval) or nil end
    end

    local genTypeValidator      = function(ptype)
        local pname             = tostring(ptype)
        local msg               = "the %s must be a" .. (pname:match("^[aeiou]") and "n" or "") .. " " .. pname
        local valid             = ptype.Validate
        return function(val, onlyvalid) return not valid(val) and (onlyvalid or msg) or nil end
    end

    local getAttributeName      = function(self) return namespace.GetNamespaceName(getmetatable(self)) end

    local regSelfOrObject       = function(self, tbl) attribute.Register(type(tbl) == "table" and prototype.NewObject(self, tbl) or self) end

    local parseLambda           = function(value, onlyvalid)
        if _LambdaCache[value] then return end
        if not (type(value) == "string" and strfind(value, "=>")) then return onlyvalid or "the %s must be a string like 'x,y=>x+y'" end

        local param, body       = strmatch(value, "^(.-)=>(.+)$")
        param                   = param and strgsub(param, "[^_%w]+", ",")
        body                    = body and strfind(body, "return") and body or ("return " .. (body or ""))

        local func              = loadSnippet(strformat("return function(%s) %s end", param, body), value, _G)
        if not func then return onlyvalid or "the %s must be a string like 'x,y => x+y'" end
        func                    = func()

        _LambdaCache            = saveStorage(_LambdaCache, value, func)
    end

    local parseCallable         = function(value, onlyvalid)
        local stype             = type(value)
        if stype == "function" then return end
        if stype == "string" then
            return parseLambda(value, true) and (onlyvalid or "the %s isn't callable") or nil
        end
        local meta = getmetatable(value)
        if not (meta and getClassMeta(meta, "__call")) then
            return onlyvalid or "the %s isn't callable"
        end
    end

    -----------------------------------------------------------------------
    --                             prototype                             --
    -----------------------------------------------------------------------
    namespace.SaveNamespace("System.Prototype",   prototype (prototype,   { __tostring = namespace.GetNamespaceName }))
    namespace.SaveNamespace("System.Attribute",   prototype (attribute,   { __tostring = namespace.GetNamespaceName }))
    namespace.SaveNamespace("System.Environment", prototype (environment, { __tostring = namespace.GetNamespaceName }))
    namespace.SaveNamespace("System.Namespace",   prototype (namespace,   { __tostring = namespace.GetNamespaceName }))
    namespace.SaveNamespace("System.Enum",        prototype (enum,        { __tostring = namespace.GetNamespaceName }))
    namespace.SaveNamespace("System.Struct",      prototype (struct,      { __tostring = namespace.GetNamespaceName }))
    namespace.SaveNamespace("System.Member",      prototype (member,      { __tostring = namespace.GetNamespaceName }))
    namespace.SaveNamespace("System.Interface",   prototype (interface,   { __tostring = namespace.GetNamespaceName }))
    namespace.SaveNamespace("System.Class",       prototype (class,       { __tostring = namespace.GetNamespaceName }))
    namespace.SaveNamespace("System.Event",       prototype (event,       { __tostring = namespace.GetNamespaceName }))
    namespace.SaveNamespace("System.Property",    prototype (property,    { __tostring = namespace.GetNamespaceName }))

    namespace.SaveNamespace("System.Platform",    prototype { __index = PLOOP_PLATFORM_SETTINGS, __tostring = namespace.GetNamespaceName })

    -----------------------------------------------------------------------
    --                             attribute                             --
    -----------------------------------------------------------------------
    -----------------------------------------------------------------------
    -- Mark a class as abstract, so it can't be used to generate objects,
    -- or mark the object methods, object features(like event, property) as
    -- abstract, so they need(not must) be implemented by child interfaces
    -- or classes
    --
    -- @attribute   System.__Abstract__
    -----------------------------------------------------------------------
    namespace.SaveNamespace("System.__Abstract__",              prototype {
        __index                 = {
            ["ApplyAttribute"]  = function(self, target, targettype, owner, name, stack)
                if targettype == ATTRTAR_INTERFACE or targettype == ATTRTAR_CLASS then
                    getmetatable(target).SetAbstract(target, parsestack(stack) + 1)
                elseif class.Validate(owner) or interface.Validate(owner) then
                    getmetatable(owner).SetAbstract(owner, name, parsestack(stack) + 1)
                end
            end,
            ["AttributeTarget"] = ATTRTAR_INTERFACE + ATTRTAR_CLASS + ATTRTAR_METHOD + ATTRTAR_EVENT + ATTRTAR_PROPERTY,
        },
        __call = regSelfOrObject, __newindex = readOnly, __tostring = namespace.GetNamespaceName
    })

    -----------------------------------------------------------------------
    -- Mark an interface so it'll auto create an anonymous class that extend
    -- the interface. So the interface can be used like a class to generate
    -- objects. Since the anonymous class don't have any constructor, no
    -- arguments can be accepted by the interface, but you still can pass
    -- a table as the init-table(like the class without constructor).
    --
    -- If the interface has only one abstract object method(include extend),
    -- it also can receive a function as argument to generate an object, the
    -- accepted function will override the abstract method :
    --
    --          import "System"
    --
    --          __AnonymousClass__()
    --          interface "ITask" (function(_ENV)
    --              __Abstract__()
    --              function DoTask(self)
    --              end
    --
    --              function Process(self)
    --                  self:DoTask()
    --              end
    --          end)
    --
    --          o = ITask(function() print("Hello") end)
    --
    --          o:Process()     -- Hello
    --
    -- @attribute   System.__AnonymousClass__
    -----------------------------------------------------------------------
    namespace.SaveNamespace("System.__AnonymousClass__",        prototype {
        __index                 = {
            ["ApplyAttribute"]  = function(self, target, targettype, owner, name, stack)
                interface.SetAnonymousClass(target, parsestack(stack) + 1)
            end,
            ["AttributeTarget"] = ATTRTAR_INTERFACE,
        },
        __call = regSelfOrObject, __newindex = readOnly, __tostring = namespace.GetNamespaceName
    })

    -----------------------------------------------------------------------
    -- Set the target struct's base struct, works like
    --
    --          struct "Number" { function (val) return type(val) ~= "number" and "the %s must be number" end }
    --
    --          __Base__(Number)
    --          struct "Integer" { function(val) return math.floor(val) ~= val and "the %s must be integer" end}
    --
    --          print(Integer(true))    -- Error: the value must be number
    --          print(Integer(1.3))     -- Error: the value must be integer
    --
    -- @attribute   System.__Base__
    -----------------------------------------------------------------------
    namespace.SaveNamespace("System.__Base__",                  prototype {
        __index                 = {
            ["ApplyAttribute"]  = function(self, target, targettype, owner, name, stack)
                struct.SetBaseStruct(target, self[1], parsestack(stack) + 1)
            end,
            ["AttributeTarget"] = ATTRTAR_STRUCT,
        },
        __call = function(self, value)
            attribute.Register(prototype.NewObject(self, { value }))
        end,
        __newindex = readOnly, __tostring = getAttributeName
    })

    -----------------------------------------------------------------------
    -- Set a default value to the enum or custom struct
    --
    -- @attribute   System.__Default__
    -----------------------------------------------------------------------
    __Default__ = namespace.SaveNamespace("System.__Default__", prototype {
        __index                 = {
            ["ApplyAttribute"]  = function(self, target, targettype, owner, name, stack)
                local value     = self[1]
                if value       ~= nil then
                    stack       = parsestack(stack) + 1

                    if targettype == ATTRTAR_ENUM then
                        enum.SetDefault(target, value, stack)
                    elseif targettype == ATTRTAR_STRUCT then
                        struct.SetDefault(target, value, stack)
                    end
                end
            end,
            ["AttributeTarget"] = ATTRTAR_ENUM + ATTRTAR_STRUCT,
        },
        __call = function(self, value)
            attribute.Register(prototype.NewObject(self, { value }))
        end,
        __newindex = readOnly, __tostring = getAttributeName
    })

    -----------------------------------------------------------------------
    -- Set a event change handler to the event
    --
    -- @attribute   System.__EventChangeHandler__
    -----------------------------------------------------------------------
    namespace.SaveNamespace("System.__EventChangeHandler__",    prototype {
        __index                 = {
            ["ApplyAttribute"]  = function(self, target, targettype, owner, name, stack)
                local value     = self[1]
                if type(value) == "function" then
                    event.SetEventChangeHandler(target, value, parsestack(stack) + 1)
                end
            end,
            ["AttributeTarget"] = ATTRTAR_EVENT,
        },
        __call = function(self, value)
            attribute.Register(prototype.NewObject(self, { value }))
        end,
        __newindex = readOnly, __tostring = getAttributeName
    })

    -----------------------------------------------------------------------
    -- Mark a class or interface as final, so they can't be inherited or
    -- extended, or mark the object methods, object features as final, so
    -- they have the highest priority to be inherited
    --
    -- @attribute   System.__Final__
    -----------------------------------------------------------------------
    __Final__ = namespace.SaveNamespace("System.__Final__",     prototype {
        __index                 = {
            ["ApplyAttribute"]  = function(self, target, targettype, owner, name, stack)
                if targettype == ATTRTAR_INTERFACE or targettype == ATTRTAR_CLASS then
                    getmetatable(target).SetFinal(target, parsestack(stack) + 1)
                elseif class.Validate(owner) or interface.Validate(owner) then
                    getmetatable(owner).SetFinal(owner, name, parsestack(stack) + 1)
                end
            end,
            ["AttributeTarget"] = ATTRTAR_INTERFACE + ATTRTAR_CLASS + ATTRTAR_METHOD + ATTRTAR_EVENT + ATTRTAR_PROPERTY,
        },
        __call = regSelfOrObject, __newindex = readOnly, __tostring = namespace.GetNamespaceName
    })

    -----------------------------------------------------------------------
    -- Set the enum as flags enumeration
    --
    -- @attribute   System.__Flags__
    -----------------------------------------------------------------------
    __Flags__ = namespace.SaveNamespace("System.__Flags__",     prototype {
        __index                 = {
            ["InitDefinition"]  = function(self, target, targettype, definition, owner, name, stack)
                local cache     = _Cache()
                local valkey    = nil
                local count     = 0
                local max       =-1

                stack           = parsestack(stack) + 1

                if type(definition) ~= "table" then error("the enum's definition must be a table", stack) end

                if enum.IsSealed(target) then
                    for name, val in enum.GetEnumValues(target) do
                        cache[val]      = name
                        if type(val) == "number" and val > 0 then
                            local n     = mlog(val) / mlog(2)
                            if floor(n) == n then
                                count   = count + 1
                                max     = n > max and n or max
                            end
                        end
                    end
                end

                -- Scan
                for k, val in pairs, definition do
                    local v         = tonumber(val)

                    if v then
                        if v == 0 then
                            if cache[0] then
                                error(strformat("The %s and %s can't be the same value", k, cache[0]), stack)
                            else
                                cache[0] = k
                            end
                        elseif v > 0 then
                            count   = count + 1

                            local n = mlog(v) / mlog(2)
                            if floor(n) == n then
                                if cache[v] then
                                    error(strformat("The %s and %s can't be the same value", k, cache[v]), stack)
                                else
                                    cache[v]    = k
                                    max         = n > max and n or max
                                end
                            else
                                error(strformat("The %s's value is not a valid flags value(2^n)", k), stack)
                            end
                        else
                            error(strformat("The %s's value is not a valid flags value(2^n)", k), stack)
                        end
                    elseif type(k) == "string" then
                        count   = count + 1
                        definition[k]= -1
                    elseif type(k) == "number" and type(val) == "string" then
                        definition[k]= nil
                        valkey  = valkey or _Cache()
                        tinsert(valkey, val)
                        count   = count + 1
                    end
                end

                if valkey then
                    for _, v in ipairs, valkey, 0 do
                        definition[v] = -1
                    end
                    _Cache(valkey)
                end

                -- So the definition would be more precisely
                if max >= count then error("The flags enumeration's value can't be greater than 2^(count - 1)", stack) end

                -- Auto-gen values
                local n     = 1
                for k, v in pairs, definition do
                    if v == -1 then
                        while cache[n] do n = 2 * n end
                        cache[n]        = k
                        definition[k]   = n
                    end
                end

                _Cache(cache)
            end,
            ["ApplyAttribute"]  = function(self, target, targettype, owner, name, stack)
                enum.SetFlagsEnum(target, parsestack(stack) + 1)
            end,
            ["AttributeTarget"] = ATTRTAR_ENUM,
        },
        __call = regSelfOrObject, __newindex = readOnly, __tostring = namespace.GetNamespaceName
    })

    -----------------------------------------------------------------------
    -- Modify the property's get process
    --
    -- @attribute   System.__Get__
    -----------------------------------------------------------------------
    namespace.SaveNamespace("System.__Get__",                   prototype {
        __index                 = {
            ["ApplyAttribute"]  = function(self, target, targettype, owner, name, stack)
                local value     = self[1]
                if type(value) == "number" then
                    stack       = parsestack(stack) + 1

                    if enum.ValidateFlags(PropertyGet.Clone, value) or enum.ValidateFlags(PropertyGet.DeepClone, value) then
                        property.GetClone(target, enum.ValidateFlags(PropertyGet.DeepClone, value), stack)
                    end
                end
            end,
            ["AttributeTarget"] = ATTRTAR_PROPERTY,
        },
        __call = function(self, value)
            attribute.Register(prototype.NewObject(self, { value }))
        end,
        __newindex = readOnly, __tostring = getAttributeName
    })

    -----------------------------------------------------------------------
    -- Set the class's objects so access non-existent fields on them will
    -- be denied
    --
    -- @attribute   System.__NoNilValue__
    -----------------------------------------------------------------------
    namespace.SaveNamespace("System.__NoNilValue__",            prototype {
        __index                 = {
            ["ApplyAttribute"]  = function(self, target, targettype, owner, name, stack)
                class.SetNilValueBlocked(target, parsestack(stack) + 1)
            end,
            ["AttributeTarget"] = ATTRTAR_CLASS,
        },
        __call = regSelfOrObject, __newindex = readOnly, __tostring = namespace.GetNamespaceName
    })

    -----------------------------------------------------------------------
    -- Set the class's objects so save value to non-existent fields on them
    --  will be denied
    --
    -- @attribute   System.__NoRawSet__
    -----------------------------------------------------------------------
    namespace.SaveNamespace("System.__NoRawSet__",              prototype {
        __index                 = {
            ["ApplyAttribute"]  = function(self, target, targettype, owner, name, stack)
                class.SetRawSetBlocked(target, parsestack(stack) + 1)
            end,
            ["AttributeTarget"] = ATTRTAR_CLASS,
        },
        __call = regSelfOrObject, __newindex = readOnly, __tostring = namespace.GetNamespaceName
    })

    -----------------------------------------------------------------------
    -- Set the class's objects so they don't use the super object access
    -- style like `super[self]:Method()`, `super[self].Name = xxx`
    --
    -- @attribute   System.__NoSuperObject__
    -----------------------------------------------------------------------
    namespace.SaveNamespace("System.__NoSuperObject__",         prototype {
        __index                 = {
            ["ApplyAttribute"]  = function(self, target, targettype, owner, name, stack)
                class.SetNoSuperObject(target, parsestack(stack) + 1)
            end,
            ["AttributeTarget"] = ATTRTAR_CLASS,
        },
        __call = regSelfOrObject, __newindex = readOnly, __tostring = namespace.GetNamespaceName
    })

    -----------------------------------------------------------------------
    -- Set the class's objects so functions that be assigned on them will
    -- be modified by the attribute system
    --
    -- @attribute   System.__ObjFuncAttr__
    -----------------------------------------------------------------------
    namespace.SaveNamespace("System.__ObjFuncAttr__",           prototype {
        __index                 = {
            ["ApplyAttribute"]  = function(self, target, targettype, owner, name, stack)
                class.SetObjectFunctionAttributeEnabled(target, parsestack(stack) + 1)
            end,
            ["AttributeTarget"] = ATTRTAR_CLASS,
        },
        __call = regSelfOrObject, __newindex = readOnly, __tostring = namespace.GetNamespaceName
    })

    -----------------------------------------------------------------------
    -- Set the class's objects to save the source where it's created
    --
    -- @attribute   System.__ObjectSource__
    -----------------------------------------------------------------------
    __ObjectSource__ = namespace.SaveNamespace("System.__ObjectSource__", prototype {
        __index                 = {
            ["ApplyAttribute"]  = function(self, target, targettype, owner, name, stack)
                if targettype == ATTRTAR_CLASS then
                    class.SetObjectSourceDebug(target, parsestack(stack) + 1)
                end
            end,
            ["AttributeTarget"] = ATTRTAR_CLASS + ATTRTAR_INTERFACE,
            ["Inheritable"]     = false,
        },
        __call = regSelfOrObject, __newindex = readOnly, __tostring = namespace.GetNamespaceName
    })

    -----------------------------------------------------------------------
    -- Set a require class to the target interface
    --
    -- @attribute   System.__Require__
    -----------------------------------------------------------------------
    namespace.SaveNamespace("System.__Require__",               prototype {
        __index                 = {
            ["ApplyAttribute"]  = function(self, target, targettype, owner, name, stack)
                interface.GetRequireClass(target, self[1], parsestack(stack) + 1)
            end,
            ["AttributeTarget"] = ATTRTAR_INTERFACE,
        },
        __call = function(self, value)
            attribute.Register(prototype.NewObject(self, { value }))
        end,
        __newindex = readOnly, __tostring = getAttributeName
    })

    -----------------------------------------------------------------------
    -- Seal the enum, struct, interface or class, so they can't be re-defined
    --
    -- @attribute   System.__Sealed__
    -----------------------------------------------------------------------
    __Sealed__ = namespace.SaveNamespace("System.__Sealed__",   prototype {
        __index                 = {
            ["ApplyAttribute"]  = function(self, target, targettype, owner, name, stack)
                getmetatable(target).SetSealed(target, parsestack(stack) + 1)
            end,
            ["AttributeTarget"] = ATTRTAR_ENUM + ATTRTAR_STRUCT + ATTRTAR_INTERFACE + ATTRTAR_CLASS,
        },
        __call = regSelfOrObject, __newindex = readOnly, __tostring = namespace.GetNamespaceName
    })

    -----------------------------------------------------------------------
    -- Modify the property's assignment, works like :
    --
    -- @attribute   System.__Set__
    -----------------------------------------------------------------------
    namespace.SaveNamespace("System.__Set__",                   prototype {
        __index                 = {
            ["ApplyAttribute"]  = function(self, target, targettype, owner, name, stack)
                local value     = self[1]
                if type(value) == "number" then
                    stack       = parsestack(stack) + 1

                    if enum.ValidateFlags(PropertySet.Clone, value) or enum.ValidateFlags(PropertySet.DeepClone, value) then
                        property.SetClone(target, enum.ValidateFlags(PropertySet.DeepClone, value), stack)
                    end

                    if enum.ValidateFlags(PropertySet.Retain, value) then
                        property.SetRetainObject(target, stack)
                    end

                    if enum.ValidateFlags(PropertySet.Weak, value) then
                        property.SetWeak(target, stack)
                    end
                end
            end,
            ["AttributeTarget"] = ATTRTAR_PROPERTY,
        },
        __call = function(self, value)
            attribute.Register(prototype.NewObject(self, { value }))
        end,
        __newindex = readOnly, __tostring = getAttributeName
    })

    -----------------------------------------------------------------------
    -- Set the class as a single version class, so all old objects of it
    -- will always use the newest definition
    --
    -- @attribute   System.__Simple__
    -----------------------------------------------------------------------
    namespace.SaveNamespace("System.__SingleVer__",             prototype {
        __index                 = {
            ["ApplyAttribute"]  = function(self, target, targettype, owner, name, stack)
                class.SetSingleVersion(target, parsestack(stack) + 1)
            end,
            ["AttributeTarget"] = ATTRTAR_CLASS,
        },
        __call = regSelfOrObject, __newindex = readOnly, __tostring = namespace.GetNamespaceName
    })

    -----------------------------------------------------------------------
    -- Set the object methods or object features as static, so they can only
    -- be used by the struct, interface or class itself
    --
    -- @attribute   System.__Simple__
    -----------------------------------------------------------------------
    namespace.SaveNamespace("System.__Static__",                prototype {
        __index                 = {
            ["InitDefinition"]  = function(self, target, targettype, definition, owner, name, stack)
                if targettype  == ATTRTAR_METHOD then
                    getmetatable(owner).SetStaticMethod(owner, name, parsestack(stack) + 1)
                end
            end,
            ["ApplyAttribute"]  = function(self, target, targettype, owner, name, stack)
                stack           = parsestack(stack) + 1
                if targettype == ATTRTAR_EVENT then
                    event.SetStatic(target, stack)
                elseif targettype == ATTRTAR_PROPERTY then
                    property.SetStatic(target, stack)
                end
            end,
            ["AttributeTarget"] = ATTRTAR_METHOD + ATTRTAR_EVENT + ATTRTAR_PROPERTY,
            ["Priority"]        = 9999,     -- Should be applied at the first for method
        },
        __call = regSelfOrObject, __newindex = readOnly, __tostring = namespace.GetNamespaceName
    })

    -----------------------------------------------------------------------
    -- Set a super class to the target class
    --
    -- @attribute   System.__Require__
    -----------------------------------------------------------------------
    namespace.SaveNamespace("System.__Super__",                 prototype {
        __index                 = {
            ["ApplyAttribute"]  = function(self, target, targettype, owner, name, stack)
                class.SetSuperClass(target, self[1], parsestack(stack) + 1)
            end,
            ["AttributeTarget"] = ATTRTAR_CLASS,
        },
        __call = function(self, value)
            attribute.Register(prototype.NewObject(self, { value }))
        end,
        __newindex = readOnly, __tostring = getAttributeName
    })

    -----------------------------------------------------------------------
    -- Create an index auto-increased enumeration
    --
    -- @attribute   System.__AutoIndex__
    -- @usage       __AutoIndex__ { A = 0, C = 10 }
    --              enum "Test" { "A", "B", "C", "D" }
    --              print(Test.A, Test.B, Test.C, Test.D) -- 0, 1, 10, 11
    -----------------------------------------------------------------------
    namespace.SaveNamespace("System.__AutoIndex__",             prototype {
        __index                 = {
            ["InitDefinition"]  = function(self, target, targettype, definition, owner, name, stack)
                local value     = self[1]
                stack           = parsestack(stack) + 1

                local newdef    = {}
                local idx       = 0

                if value and type(value) ~= "table" then value = nil end

                for _, name in ipairs, definition, 0 do
                    idx         = value and value[name] or (idx + 1)
                    newdef[name]= idx
                end

                return newdef
            end,
            ["AttributeTarget"] = ATTRTAR_ENUM,
        },
        __call = function(self, value)
            attribute.Register(prototype.NewObject(self, { value }))
        end,
        __newindex = readOnly, __tostring = getAttributeName
    })

    -------------------------------------------------------------------------------
    --                               registration                                --
    -------------------------------------------------------------------------------
    environment.RegisterGlobalNamespace("System")

    -----------------------------------------------------------------------
    --                               enums                               --
    -----------------------------------------------------------------------
    --- The attribute targets
    __Sealed__() __Flags__() __Default__(ATTRTAR_ALL)
    enum "System.AttributeTargets" {
        All         = ATTRTAR_ALL,
        Function    = ATTRTAR_FUNCTION,
        Namespace   = ATTRTAR_NAMESPACE,
        Enum        = ATTRTAR_ENUM,
        Struct      = ATTRTAR_STRUCT,
        Member      = ATTRTAR_MEMBER,
        Method      = ATTRTAR_METHOD,
        Interface   = ATTRTAR_INTERFACE,
        Class       = ATTRTAR_CLASS,
        Event       = ATTRTAR_EVENT,
        Property    = ATTRTAR_PROPERTY,
    }

    --- The attribute priorty
    __Sealed__() __Default__(0)
    enum "System.AttributePriorty" {
        Highest     =  2,
        Higher      =  1,
        Normal      =  0,
        Lower       = -1,
        Lowest      = -2,
    }

    --- the property set settings
    __Sealed__() __Flags__() __Default__(0)
    PropertySet = enum "System.PropertySet" {
        Assign      = 0,
        Clone       = 1,
        DeepClone   = 2,
        Retain      = 4,
        Weak        = 8,
    }

    --- the property get settings
    __Sealed__() __Flags__() __Default__(0)
    PropertyGet = enum "System.PropertyGet" {
        Origin      = 0,
        Clone       = 1,
        DeepClone   = 2,
    }

    --- the struct category
    __Sealed__()
    enum "System.StructCategory" {
        "MEMBER",
        "ARRAY",
        "CUSTOM"
    }

    -----------------------------------------------------------------------
    --                              structs                              --
    -----------------------------------------------------------------------
    --- Represents any value
    __Sealed__() struct "System.Any"                { }

    --- Represents boolean value
    __Sealed__() Boolean = struct "System.Boolean"  { genBasicValidator("boolean")  }

    --- Represents string value
    __Sealed__() String = struct "System.String"    { genBasicValidator("string")   }

    --- Represents number value
    __Sealed__() Number = struct "System.Number"    { genBasicValidator("number")   }

    --- Represents function value
    __Sealed__() struct "System.Function"           { genBasicValidator("function") }

    --- Represents table value
    __Sealed__() Table = struct "System.Table"      { genBasicValidator("table")    }

    --- Represents userdata value
    __Sealed__() struct "System.Userdata"           { genBasicValidator("userdata") }

    --- Represents thread value
    __Sealed__() struct "System.Thread"             { genBasicValidator("thread")   }

    --- Converts any value to boolean
    __Sealed__() struct "System.AnyBool"            { false, __init = function(val) return val and true or false end }

    --- Represents non-empty string
    __Sealed__() struct "System.NEString"           { __base = String, function(val, onlyvalid) return strtrim(val) == "" and (onlyvalid or "the %s can't be an empty string") or nil end, __init = strtrim }

    --- Represents table value without meta-table
    __Sealed__() struct "System.RawTable"           { __base = Table, function(val, onlyvalid) return getmetatable(val) ~= nil and (onlyvalid or "the %s must have no meta-table") or nil end  }

    --- Represents integer value
    __Sealed__() Integer = struct "System.Integer"  { __base = Number, function(val, onlyvalid) return floor(val) ~= val and (onlyvalid or "the %s must be an integer") or nil end }

    --- Represents natural number value
    __Sealed__() struct "System.NaturalNumber"      { __base = Integer, function(val, onlyvalid) return val < 0 and (onlyvalid or "the %s must be a natural number") or nil end }

    --- Represents namespace type
    __Sealed__() struct "System.NamespaceType"      { genTypeValidator(namespace)   }

    --- Represents enum type
    __Sealed__() struct "System.EnumType"           { genTypeValidator(enum)        }

    --- Represents struct type
    __Sealed__() struct "System.StructType"         { genTypeValidator(struct)      }

    --- Represents interface type
    __Sealed__() struct "System.InterfaceType"      { genTypeValidator(interface)   }

    --- Represents class type
    __Sealed__() struct "System.ClassType"          { genTypeValidator(class)       }

    --- Represents any validation type
    __Sealed__() AnyType = struct "System.AnyType"  { function(val, onlyvalid) return not getprototypemethod(val, "ValidateValue") and (onlyvalid or "the %s is not a validation type") or nil end}

    --- Represents lambda value, used to string like 'x, y => x + y' to function
    __Sealed__() struct "System.Lambda"             { __init = function(value) return _LambdaCache[value] end, parseLambda }

    --- Represents callable value, like function, lambda, callable object generate by class
    __Sealed__() struct "System.Callable"           { __init = function(value) if type(value) == "string" then return _LambdaCache[value] end end, parseCallable }

    --- Represents the variable types for arguments or return values
    __Sealed__() Variable = struct "System.Variable"{
        { name = "type",        type = AnyType  },
        { name = "nilable",     type = Boolean  },
        { name = "default",                     },
        { name = "name",        type = String   },
        { name = "islist",      type = Boolean  },
        { name = "validate"                     },  -- auto generated
        { name = "immutable"                    },  -- auto generated

        function (var, onlyvalid)
            if var.default ~= nil then
                if var.islist then return onlyvalid or "the %s is a list, can't have default value" end
                if not var.nilable then return onlyvalid or "the %s is not nilable, can't have default value" end
                if var.type then
                    local ret, msg  = getprototypemethod(var.type, "ValidateValue")(var.type, var.default, true)
                    if msg then return onlyvalid or "the %s.default don't match its type" end
                end
            end
        end,

        __init = function (var)
            if var.type then
                var.validate = getprototypemethod(var.type, "ValidateValue")
                var.immutable= getobjectvalue(var.type, "IsImmutable")

                if var.default ~= nil then
                    var.default = var.validate(var.type, var.default)
                end
            else
                var.validate = nil
                var.immutable= true
            end

            if var.nilable and var.default ~= nil then
                var.immutable= false
            end
        end,
    }

    --- Represents variables list
    __Sealed__() struct "System.Variables"          { __array = Variable + AnyType,
        function(vars, onlyvalid)
            local opt   = false
            local lst   = false

            for i, var in ipairs, vars, 0 do
                if lst then return onlyvalid or "the %s's list variable must be the last one" end
                if getmetatable(var) == nil then
                    if var.islist then
                        if opt then return onlyvalid or "the %s's list variable and optional variable can't be use together" end
                        lst = true
                    elseif var.nilable then
                        opt = true
                    elseif opt then
                        return onlyvalid or "the %s's non-optional variables must exist before the optional variables"
                    end
                elseif opt then
                    return onlyvalid or "the %s's non-optional variables must exist before the optional variables"
                end
            end
        end,

        __init  = function(vars)
            for i, var in ipairs, vars, 0 do
                if getmetatable(var) ~= nil then
                    vars[i] = Variable(var)
                end
            end
        end,
    }

    -----------------------------------------------------------------------
    --                             interface                             --
    -----------------------------------------------------------------------
    --- the interface of attribtue
    __Sealed__() __ObjectSource__{ Inheritable = true }
    interface "System.IAttribtue" (function(_ENV)

        export {
            GetObjectSource = Class.GetObjectSource,
            tostring        = tostring,
            getmetatable    = getmetatable,
        }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- Get the attached attribute data of the target
        -- @param   target                      the target
        -- @param   owner                       the target's owner
        -- @return  any                         the attached data
        GetAttachedData             = Attribute.GetAttachedData

        --- Get all targets have attached data of the attribtue
        -- @format  ([cache])
        -- @param   cache                       the cache to save the result
        -- @rformat (cache)                     the cache that contains the targets
        -- @rformat (iter, attr)                without the cache parameter, used in generic for
        GetAttributeTargets         = Attribute.GetAttributeTargets

        --- Get all target's owners that have attached data of the attribtue
        -- @format  ([cache])
        -- @param   cache                       the cache to save the result
        -- @rformat (cache)                     the cache that contains the targets
        -- @rformat (iter, attr)                without the cache parameter, used in generic for
        GetAttributeTargetOwners    = Attribute.GetAttributeTargetOwners

        -----------------------------------------------------------
        --                       property                       --
        -----------------------------------------------------------
        --- the attribute target
        __Abstract__() property "AttributeTarget"  { type = AttributeTargets        }

        --- whether the attribute is inheritable
        __Abstract__() property "Inheritable"      { type = Boolean                 }

        --- whether the attribute is overridable
        __Abstract__() property "Overridable"      { type = Boolean, default = true }

        --- the attribute's priority
        __Abstract__() property "Priority"         { type = AttributePriorty        }

        --- the attribute's sub level of priority
        __Abstract__() property "SubLevel"         { type = Number,  default = 0    }

        -----------------------------------------------------------
        --                      initializer                      --
        -----------------------------------------------------------
        IAttribtue          = Attribute.Register

        -----------------------------------------------------------
        --                      meta-method                      --
        -----------------------------------------------------------
        function __tostring(self) return tostring(getmetatable(self) .. (GetObjectSource(self) or "")) end
    end)

    --- the interface to modify the target's definition
    __Sealed__()
    interface "System.IInitAttribtue" (function(_ENV)
        extend "IAttribtue"

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- modify the target's definition
        -- @param   target                      the target
        -- @param   targettype                  the target type
        -- @param   definition                  the target's definition
        -- @param   owner                       the target's owner
        -- @param   name                        the target's name in the owner
        -- @param   stack                       the stack level
        -- @return  definition                  the new definition
        __Abstract__()
        function InitDefinition(self, target, targettype, definition, owner, name, stack)
        end
    end)

    --- the interface to apply changes on the target
    __Sealed__()
    interface "System.IApplyAttribtue" (function(_ENV)
        extend "IAttribtue"

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- apply changes on the target
        -- @param   target                      the target
        -- @param   targettype                  the target type
        -- @param   owner                       the target's owner
        -- @param   name                        the target's name in the owner
        -- @param   stack                       the stack level
        __Abstract__()
        function ApplyAttribute(self, target, targettype, owner, name, stack)
        end
    end)

    --- the interface to attach data on the target
    __Sealed__()
    interface "System.IAttachAttribtue" (function(_ENV)
        extend "IAttribtue"

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- attach data on the target
        -- @param   target                      the target
        -- @param   targettype                  the target type
        -- @param   owner                       the target's owner
        -- @param   name                        the target's name in the owner
        -- @param   stack                       the stack level
        -- @return  data                        the attribute data to be attached
        __Abstract__()
        function AttachAttribute(self, target, targettype, owner, name, stack)
        end
    end)

    -----------------------------------------------------------------------
    --                              classes                              --
    -----------------------------------------------------------------------
    --- the attribute to build the overload system
    __Sealed__() __Final__()
    class (_PLoopEnv, "System.__Arguments__") (function(_ENV)
        extend "IInitAttribtue"

        -----------------------------------------------------------
        --                        storage                        --
        -----------------------------------------------------------
        _OverloadMap            = newStorage(WEAK_KEY)
        _ArgValdMap             = {}
        _OverloadMap            = {}

        -----------------------------------------------------------
        --                        constant                       --
        -----------------------------------------------------------
        FLD_VAR_FUNCTN          =  0
        FLD_VAR_MINARG          = -1
        FLD_VAR_MAXARG          = -2
        FLD_VAR_ISLIST          = -3
        FLD_VAR_IMMTBL          = -4
        FLD_VAR_USGMSG          = -5
        FLD_VAR_VARVLD          = -6

        FLD_OVD_FUNCTN          =  0
        FLD_OVD_OWNER           = -1
        FLD_OVD_NAME            = -2

        TYPE_VALD_DISD          = Platform.TYPE_VALIDATION_DISABLED

        NO_SELF_METHOD          = {
            __new               = true,
            __exist             = true,
        }

        CTOR_NAME               = "__ctor"

        THORW_METHOD            = {
            __exist             = true,
            __new               = true,
            __ctor              = true,
        }

        FLG_VAR_METHOD          = newflags(true)    -- is method
        FLG_VAR_SELFIN          = newflags()        -- has self
        FLG_VAR_IMMTBL          = newflags()        -- all immutable
        FLG_VAR_ISLIST          = newflags()        -- the last variable is list
        FLG_VAR_IMMLST          = newflags()        -- the list variable is immutable
        FLG_VAR_LSTNIL          = newflags()        -- the list variable is nilable
        FLG_VAR_LSTVLD          = newflags()        -- the list variable has type
        FLG_VAR_LENGTH          = newflags()        -- the multiply factor of length

        FLG_OVD_SELFIN          = newflags(true)    -- has elf
        FLG_OVD_THROW           = newflags()        -- use throw
        FLG_OVD_ONECNT          = newflags()        -- only one variable list

        ORDINAL_NUMBER          = { "1st", "2nd", "3rd" }

        -----------------------------------------------------------
        --                        helpers                        --
        -----------------------------------------------------------
        export {
            validate            = Struct.ValidateValue,
            geterrmsg           = Struct.GetErrorMessage,
            saveStorage         = saveStorage,
            ipairs              = ipairs,
            getobjectvalue      = getobjectvalue,
            tinsert             = tinsert,
            uinsert             = uinsert,
            tblconcat           = tblconcat,
            strformat           = strformat,
            strgsub             = strgsub,
            type                = type,
            getmetatable        = getmetatable,
            tostring            = tostring,
            loadSnippet         = loadSnippet,
            _Cache              = _Cache,
            turnOnFlags         = turnOnFlags,
            validateFlags       = validateFlags,
            parseOrdinalNumber  = function (i) return ORDINAL_NUMBER[i] or (i .. "th") end,
            unpack              = unpack,
            error               = error,
            select              = select,
        }

        export { Enum, Struct, Interface, Class, Variables, AttributeTargets, StructCategory, __Arguments__ }

        local function serializeData(data)
            local dtype         = type(data)

            if dtype == "string" then
                return strformat("%q", data)
            elseif dtype == "number" or dtype == "boolean" then
                return tostring(data)
            else
                return "(inner)"
            end
        end

        local function serialize(data, ns)
            if ns then
                if Enum.Validate(ns) then
                    if Enum.IsFlagsEnum(ns) then
                        local cache = {}
                        for name in ns(data) do
                            tinsert(cache, name)
                        end
                        return tblconcat(cache, " + ")
                    else
                        return Enum.Parse(ns, data)
                    end
                elseif Struct.Validate(ns) then
                    if Struct.GetStructType(ns) == StructCategory.CUSTOM then
                        return serializeData(data)
                    else
                        return "(inner)"
                    end
                else
                    return "(inner)"
                end
            end
            return serializeData(data)
        end

        local function buildUsage(vars, owner, name, ismethod)
            local usage         = {}

            if ismethod then
                if CTOR_NAME == name then
                    tinsert(usage, strformat("Usage: %s(", tostring(owner)))
                elseif NO_SELF_METHOD[name] or getmetatable(owner).IsStaticMethod(owner, name) then
                    tinsert(usage, strformat("Usage: %s.%s(", tostring(owner), name))
                else
                    tinsert(usage, strformat("Usage: %s:%s(", tostring(owner), name))
                end
            else
                tinsert(usage, strformat("Usage: %s(", name))
            end

            for i, var in ipairs, vars, 0 do
                if i > 1 then tinsert(usage, ", ") end

                if var.nilable then tinsert(usage, "[") end

                if var.name or var.islist then
                    tinsert(usage, var.islist and "..." or var.name)
                    if var.type then
                        tinsert(usage, " as ")
                    end
                end

                if var.type then
                    tinsert(usage, tostring(var.type))
                end

                if var.default ~= nil then
                    tinsert(usage, " = ")
                    tinsert(usage, serialize(var.default, var.type))
                end

                if var.nilable then tinsert(usage, "]") end
            end

            tinsert(usage, ")")

            vars[FLD_VAR_USGMSG]= tblconcat(usage, "")
        end

        local function genArgumentValid(vars, ismethod, hasself)
            local len   = #vars
            if len     == 0 then return end

            local token = len * FLG_VAR_LENGTH
            local islist= false

            if ismethod then
                token   = turnOnFlags(FLG_VAR_METHOD, token)

                if hasself then
                    token = turnOnFlags(FLG_VAR_SELFIN, token)
                end
            end

            if vars[FLD_VAR_IMMTBL] then
                token   = turnOnFlags(FLG_VAR_IMMTBL, token)
            end

            if vars[FLD_VAR_ISLIST] then
                islist  = true
                token   = turnOnFlags(FLG_VAR_ISLIST, token)
                if vars[len].immutable then
                    token = turnOnFlags(FLG_VAR_IMMLST, token)
                end
                if vars[len].type then
                    token = turnOnFlags(FLG_VAR_LSTVLD, token)
                end
                if vars[len].nilable then
                    token = turnOnFlags(FLG_VAR_LSTNIL, token)
                end
            end

            -- Build the validator generator
            if not _ArgValdMap[token] then
                local head      = _Cache()
                local body      = _Cache()
                local apis      = _Cache()
                local args      = _Cache()

                uinsert(apis, "type")
                uinsert(apis, "strgsub")
                uinsert(apis, "tostring")

                tinsert(body, "")                       -- remain for shareable variables

                for i = 1, len do args[i] = "v" .. i end
                if ismethod then
                    tinsert(body, strformat("return function(func, %s)", tblconcat(args, ", ")))
                else
                    tinsert(body, strformat("return function(usage, func, %s)", tblconcat(args, ", ")))
                end

                for i = 1, len do args[i] = "a" .. i end
                if islist then args[len] = nil end
                if ismethod and hasself then tinsert(args, 1, "self") end

                args = tblconcat(args, ", ")

                if ismethod then
                    if islist then
                        tinsert(body, strformat([[return function(onlyvalid, %s, ...)]], args))
                    else
                        tinsert(body, strformat([[return function(onlyvalid, %s)]], args))
                    end
                else
                    uinsert(apis, "error")
                    if islist then
                        tinsert(body, strformat([[return function(%s, ...)]], args))
                    else
                        tinsert(body, strformat([[return function(%s)]], args))
                    end
                end

                tinsert(body, [[local ret, msg]])

                if ismethod then tinsert(body, [[local nochange = onlyvalid ~= nil]]) end

                for i = 1, islist and (len - 1) or len do
                    if ismethod then
                        tinsert(body, (([[
                            if _ai_ == nil then
                                if not _vi_.nilable then return onlyvalid or "the _i_ argument can't be nil" end
                                _ai_ = _vi_.default
                            elseif _vi_.type then
                                ret, msg = _vi_.validate(_vi_.type, _ai_, nochange)
                                if msg then return onlyvalid or (type(msg) == "string" and strgsub(msg, "%%s%.?", "_i_ argument") or ("the _i_ argument must be " .. tostring(_vi_.type))) end
                                _ai_ = ret
                            end
                        ]]):gsub("_vi_", "v" .. i):gsub("_ai_", "a" .. i):gsub("_i_", parseOrdinalNumber(i))))
                    else
                        tinsert(body, (([[
                            if _ai_ == nil then
                                if not _vi_.nilable then error(usage .. " - the _i_ argument can't be nil", 2) end
                                _ai_ = _vi_.default
                            elseif _vi_.type then
                                ret, msg = _vi_.validate(_vi_.type, _ai_)
                                if msg then error(usage .. " - " .. (type(msg) == "string" and strgsub(msg, "%%s%.?", "_i_ argument") or ("the _i_ argument must be " .. tostring(_vi_.type))), 2) end
                                _ai_ = ret
                            end
                        ]]):gsub("_vi_", "v" .. i):gsub("_ai_", "a" .. i):gsub("_i_", parseOrdinalNumber(i))))
                    end
                end

                if not islist then
                    if ismethod then
                        tinsert(body, [[if nochange then return end]])
                    end
                    tinsert(body, strformat([[return func(%s)]], args))
                else
                    if ismethod then
                        if validateFlags(FLG_VAR_IMMLST, token) then
                            if not validateFlags(FLG_VAR_LSTNIL, token) or validateFlags(FLG_VAR_LSTVLD, token) then
                                uinsert(apis, "select")
                                tinsert(body, [[
                                    local vlen = select("#", ...)
                                ]])
                                if not validateFlags(FLG_VAR_LSTNIL, token) then
                                    tinsert(body, [[
                                        if vlen == 0 then return onlyvalid or "the ... must contains at least one argument" end
                                    ]])
                                end
                                if validateFlags(FLG_VAR_LSTVLD, token) then
                                    uinsert(apis, "parseOrdinalNumber")
                                    tinsert(body, (([[
                                        local vtype = _vi_.type
                                        local valid = _vi_.validate
                                        for i = 1, vlen do
                                            ret, msg= valid(vtype, select(i, ...), nochange)
                                            if msg then return onlyvalid or (type(msg) == "string" and strgsub(msg, "%%s%.?", parseOrdinalNumber(i + _i_) .. " argument") or ("the " .. (i + _i_) .. " argument must be " .. tostring(vtype))) end
                                        end
                                    ]]):gsub("_vi_", "v" .. len):gsub("_ai_", "a" .. len):gsub("_i_", tostring(len - 1))))
                                end
                            end

                            tinsert(body, [[if nochange then return end]])
                            tinsert(body, strformat([[return func(%s, ...)]], args))
                        else
                            uinsert(apis, "select")
                            uinsert(apis, "parseOrdinalNumber")
                            tinsert(body, [[
                                local vlen = select("#", ...)
                            ]])
                            if not validateFlags(FLG_VAR_LSTNIL, token) then
                                tinsert(body, [[
                                    if vlen == 0 then return onlyvalid or "the ... must contains at least one argument" end
                                ]])
                            end
                            tinsert(body, (([[
                                if vlen > 0 then
                                    local vtype = _vi_.type
                                    local valid = _vi_.validate

                                    if nochange then
                                        for i = 1, vlen do
                                            ret, msg= valid(vtype, select(i, ...), nochange)
                                            if msg then return onlyvalid or (type(msg) == "string" and strgsub(msg, "%%s%.?", parseOrdinalNumber(i + _i_) .. " argument") or ("the " .. (i + _i_) .. " argument must be " .. tostring(vtype))) end
                                        end
                                        return
                                    else
                                        local vlst  = { ... }
                                        for i = 1, vlen do
                                            ret, msg= valid(vtype, vlst[i], nochange)
                                            if msg then return onlyvalid or (type(msg) == "string" and strgsub(msg, "%%s%.?", parseOrdinalNumber(i + _i_) .. " argument") or ("the " .. (i + _i_) .. " argument must be " .. tostring(vtype))) end
                                            vlst[i] = ret
                                        end
                                        return func(_arg_, unpack(vlst))
                                    end
                                else
                                    if nochange then return end
                                    return func(_arg_)
                                end
                            ]]):gsub("_arg_", args):gsub("_vi_", "v" .. len):gsub("_ai_", "a" .. len):gsub("_i_", tostring(len - 1))))
                        end
                    else
                        if validateFlags(FLG_VAR_IMMLST, token) then
                            if not validateFlags(FLG_VAR_LSTNIL, token) or validateFlags(FLG_VAR_LSTVLD, token) then
                                uinsert(apis, "select")
                                tinsert(body, [[
                                    local vlen = select("#", ...)
                                ]])
                                if not validateFlags(FLG_VAR_LSTNIL, token) then
                                    tinsert(body, [[
                                        if vlen == 0 then error(usage .. " - " .. "the ... must contains at least one argument", 2) end
                                    ]])
                                end
                                if validateFlags(FLG_VAR_LSTVLD, token) then
                                    uinsert(apis, "parseOrdinalNumber")
                                    tinsert(body, (([[
                                        local vtype = _vi_.type
                                        local valid = _vi_.validate
                                        for i = 1, vlen do
                                            ret, msg= valid(vtype, (select(i, ...)))
                                            if msg then error(usage .. " - " .. (type(msg) == "string" and strgsub(msg, "%%s%.?", parseOrdinalNumber(i + _i_) .. " argument") or ("the " .. (i + _i_) .. " argument must be " .. tostring(vtype))), 2) end
                                        end
                                    ]]):gsub("_vi_", "v" .. len):gsub("_ai_", "a" .. len):gsub("_i_", tostring(len - 1))))
                                end
                            end

                            tinsert(body, strformat([[return func(%s, ...)]], args))
                        else
                            uinsert(apis, "select")
                            uinsert(apis, "parseOrdinalNumber")
                            tinsert(body, [[
                                local vlen = select("#", ...)
                            ]])
                            if not validateFlags(FLG_VAR_LSTNIL, token) then
                                tinsert(body, [[
                                    if vlen == 0 then error(usage .. " - " .. "the ... must contains at least one argument", 2) end
                                ]])
                            end
                            tinsert(body, (([[
                                if vlen > 0 then
                                    local vtype = _vi_.type
                                    local valid = _vi_.validate
                                    local vlst  = { ... }
                                    for i = 1, vlen do
                                        ret, msg= valid(vtype, vlst[i])
                                        if msg then error(usage .. " - " .. (type(msg) == "string" and strgsub(msg, "%%s%.?", parseOrdinalNumber(i + _i_) .. " argument") or ("the " .. (i + _i_) .. " argument must be " .. tostring(vtype))), 2) end
                                        vlst[i] = ret
                                    end
                                    return func(_arg_, unpack(vlst))
                                else
                                    return func(_arg_)
                                end
                            ]]):gsub("_arg_", args):gsub("_vi_", "v" .. len):gsub("_ai_", "a" .. len):gsub("_i_", tostring(len - 1))))
                        end
                    end
                end

                tinsert(body, [[
                        end
                    end
                ]])

                if #apis > 0 then
                    local declare   = tblconcat(apis, ", ")
                    body[1]         = strformat("local %s = %s", declare, declare)
                end

                _ArgValdMap[token]  = loadSnippet(tblconcat(body, "\n"), "Argument_Validate_" .. token, currentenv())()

                _Cache(body)
                _Cache(apis)
            end

            if ismethod then
                vars[FLD_VAR_VARVLD] = _ArgValdMap[token](unpack(vars, 0))
            else
                vars[FLD_VAR_VARVLD] = _ArgValdMap[token](vars[FLD_VAR_USGMSG], unpack(vars, 0))
            end
        end

        local function genOverload(overload, hasself)
            local token         = 0

            if hasself then
                token           = turnOnFlags(FLG_OVD_SELFIN, token)
            end

            if THORW_METHOD[overload[FLD_OVD_NAME]] then
                token           = turnOnFlags(FLG_OVD_THROW, token)
            end

            if #overload == 1 then
                token           = turnOnFlags(FLG_OVD_ONECNT, token)
            end

            local usages = { "the calling style must be one of the follow:" }
            for i = 1, #overload do usages[i + 1] = overload[i][FLD_VAR_USGMSG] end
            usages = tblconcat(usages, "\n    ")

            -- Build the validator generator
            if not _OverloadMap[token] then
                local body      = _Cache()
                local apis      = _Cache()

                uinsert(apis, "select")

                tinsert(body, "")                       -- remain for shareable variables

                tinsert(body, "return function(overload, count, usages)")

                if hasself then
                    tinsert(body, [[return function(self, ...)]])
                else
                    tinsert(body, [[return function(...)]])
                end

                if #overload == 1 then
                    tinsert(body, [[
                        local vars = overload[1]
                        local valid= vars[]] .. FLD_VAR_VARVLD .. [[]
                        local msg
                        if not valid then
                            if select("#", ...) > 0 then msg = "no arguments can be accepted" end
                        else
                            msg  = valid(false, ]] .. (hasself and "self, " or "") .. [[...)
                        end
                    ]])
                    if validateFlags(FLG_OVD_THROW, token) then
                        tinsert(body, [[
                            if msg then throw(vars[]] .. FLD_VAR_USGMSG .. [[] .. " - " .. msg) end
                        ]])
                    else
                        uinsert(apis, "error")
                        tinsert(body, [[
                            if msg then error(vars[]] .. FLD_VAR_USGMSG .. [[] .. " - " .. msg, 2) end
                        ]])
                    end
                    tinsert(body, [[
                        if vars[]] .. FLD_VAR_IMMTBL .. [[] then
                            return vars[]] .. FLD_VAR_FUNCTN .. [[](]] .. (hasself and "self, " or "") .. [[...)
                        else
                            return valid(nil, ]] .. (hasself and "self, " or "") .. [[...)
                        end
                    ]])
                else
                    uinsert(apis, "tblconcat")
                    tinsert(body, [[
                        local argcnt = select("#", ...)
                        if argcnt == 0 then
                            for i = 1, count do
                                local vars = overload[i]
                                if vars[]] .. FLD_VAR_MAXARG .. [[] == 0 then
                                    return vars[]] .. FLD_VAR_FUNCTN .. [[](]] .. (hasself and "self, " or "") .. [[...)
                                end
                            end
                        else
                            for i = 1, count do
                                local vars = overload[i]
                                if vars[]] .. FLD_VAR_MINARG .. [[] <= argcnt and argcnt <= vars[]] .. FLD_VAR_MAXARG .. [[] then
                                    local valid = vars[]] .. FLD_VAR_VARVLD .. [[]

                                    if valid(true, ]] .. (hasself and "self, " or "") .. [[...) == nil then
                                        if vars[]] .. FLD_VAR_IMMTBL .. [[] then
                                            return vars[]] .. FLD_VAR_FUNCTN .. [[](]] .. (hasself and "self, " or "") .. [[...)
                                        else
                                            return valid(nil, ]] .. (hasself and "self, " or "") .. [[...)
                                        end
                                    end
                                end
                            end
                        end
                        -- Raise the usages
                    ]])
                    if validateFlags(FLG_OVD_THROW, token) then
                        tinsert(body, [[
                            throw(usages)
                        ]])
                    else
                        uinsert(apis, "error")
                        tinsert(body, [[
                           error(usages, 2)
                        ]])
                    end
                end


                tinsert(body, [[
                        end
                    end
                ]])

                if #apis > 0 then
                    local declare   = tblconcat(apis, ", ")
                    body[1]         = strformat("local %s = %s", declare, declare)
                end

                _OverloadMap[token]  = loadSnippet(tblconcat(body, "\n"), "Overload_Process_" .. token, currentenv())()

                _Cache(body)
                _Cache(apis)
            end

            overload[FLD_OVD_FUNCTN] = _OverloadMap[token](overload, #overload, usages)
        end

        -----------------------------------------------------------
        --                     static method                     --
        -----------------------------------------------------------
        --- Generate an overload method to handle all rest argument groups
        __Static__() function Rest()
            Class.AttachObjectSource(__Arguments__{ { islist = true, nilable = true} }, 2)
        end

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- modify the target's definition
        -- @param   target                      the target
        -- @param   targettype                  the target type
        -- @param   definition                  the target's definition
        -- @param   owner                       the target's owner
        -- @param   name                        the target's name in the owner
        -- @param   stack                       the stack level
        -- @return  definition                  the new definition
        function InitDefinition(self, target, targettype, definition, owner, name, stack)
            local len           = #self

            local vars          = {
                [FLD_VAR_FUNCTN]= definition,
                [FLD_VAR_MINARG]= len,
                [FLD_VAR_MAXARG]= len,
                [FLD_VAR_ISLIST]= false,
                [FLD_VAR_IMMTBL]= true,
                [FLD_VAR_USGMSG]= "",
                [FLD_VAR_VARVLD]= false,
            }

            local minargs
            local immutable     = true

            for i = 1, len do
                local var       = self[i]
                vars[i]         = var
                if var.islist then
                    vars[FLD_VAR_ISLIST]    = true
                    vars[FLD_VAR_MAXARG]    = 255
                end

                if var.nilable then
                    minargs     = minargs or i - 1
                end

                if not var.immutable then
                    immutable   = false
                end
            end

            vars[FLD_VAR_MINARG]= minargs or vars[FLD_VAR_MINARG]
            vars[FLD_VAR_IMMTBL]= immutable

            if targettype == AttributeTargets.Method then
                local hasself = not (NO_SELF_METHOD[name] or getmetatable(owner).IsStaticMethod(owner, name))
                buildUsage(vars, owner, name, true)
                genArgumentValid(vars, true, hasself)

                local overload  = _OverloadMap[owner] and _OverloadMap[owner][name]

                if overload then
                    local eidx
                    -- Check if override
                    for i, evars in ipairs, overload, 0 do
                        if #evars == #vars then
                            eidx= i
                            for j, v in ipairs, evars, 0 do
                                if v.type ~= vars[j].type then
                                    eidx = nil
                                    break
                                end
                            end
                        end
                    end

                    if eidx then
                        overload= saveStorage(overload, eidx, vars)
                    else
                        overload= saveStorage(overload, #overload + 1, vars)
                    end
                else
                    overload    = { vars, [FLD_OVD_OWNER] = owner, [FLD_OVD_NAME] = name }
                end

                genOverload(overload, hasself)

                _OverloadMap    = saveStorage(_OverloadMap, owner, saveStorage(_OverloadMap[owner] or {}, name, overload))

                if #overload == 1 and TYPE_VALD_DISD and vars[FLD_VAR_IMMTBL] then return end

                return overload[FLD_OVD_FUNCTN]
            else
                if TYPE_VALD_DISD and vars[FLD_VAR_IMMTBL] then return end

                buildUsage(vars, owner, name, false)
                genArgumentValid(vars, false)

                return vars[FLD_VAR_VARVLD]
            end
        end

        -----------------------------------------------------------
        --                       property                       --
        -----------------------------------------------------------
        --- the attribute target
        property "AttributeTarget"  { type = AttributeTargets,  default = AttributeTargets.Method + AttributeTargets.Function }

        --- the attribute's priority
        property "Priority"         { type = AttributePriorty,  default = AttributePriorty.Lowest }

        --- the attribute's sub level of priority
        property "SubLevel"         { type = Number,            default = -99999 }

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        function __new(vars)
            if vars ~= nil then
                local ret, msg  = validate(Variables, vars)
                if msg then throw("Usage: __Arguments__{ ... } - " .. geterrmsg(msg, "")) end

                return vars
            else
                return {}
            end
        end
    end)

    --- Represents containers of several functions as event handlers
    __Sealed__() __Final__()
    Delegate = class (_PLoopEnv, "System.Delegate") (function(_ENV)
        event "OnChange"

        -----------------------------------------------------------
        --                        helpers                        --
        -----------------------------------------------------------
        export {
            tinsert             = tinsert,
            tremove             = tremove,
            getmetatable        = getmetatable,
            ipairs              = ipairs,
            type                = type,
            error               = error,
        }

        export { Attribute, AttributeTargets }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- Copy the handlers to the target delegate
        -- @param   target                      the target delegate
        function CopyTo(self, target)
            if getmetatable(target) == Delegate then
                local len = #self
                for i = -1, len do target[i] = self[i] end
                for i = len + 1, #target do target[i] = nil end
            end
        end

        --- Invoke the handlers with arguments
        -- @param   ...                         the arguments
        function Invoke(self, ...)
            local ret = self[0] and self[0](...) or false
            -- Any func return true means to stop all
            if ret then return end

            -- Call the stacked handlers
            for _, func in ipairs, self, 0 do
                ret = func(...)

                if ret then return end
            end

            -- Call the final func
            return self[-1] and self[-1](...)
        end

        --- Whether the delegate has no handler
        -- @return  boolean                     true if no handler in the delegate
        function IsEmpty(self)
            return not (self[-1] or self[1] or self[0])
        end

        --- Set the init function to the delegate
        -- @format  (init[, stack])
        -- @param   init                        the init function
        -- @param   stack                       the stack level
        function SetInitFunction(self, func, stack)
            if func == nil or type(func) == "function" then
                func = func or false
                if self[0] ~= func then
                    self[0] = func
                    return OnChange(self)
                end
            end
        end

        --- Set the final function to the delegate
        -- @format  (final[, stack])
        -- @param   final                       the final function
        -- @param   stack                       the stack level
        function SetFinalFunction(self, func, stack)
            if func == nil or type(func) == "function" then
                func = func or false
                if self[-1] ~= func then
                    self[-1] = func
                    return OnChange(self)
                end
            end
        end

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- The delegate's owner
        property "Owner"    { type = Table }

        --- The delegate's name
        property "Name"     { type = String }

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__{ Variable(Table, true), Variable(String, true) }
        function Delegate(self, owner, name)
            self.Owner      = owner
            self.Name       = name
        end

        -----------------------------------------------------------
        --                       meta-data                       --
        -----------------------------------------------------------
        field { [-1] = false, [0] = false }

        --- Use to add stackable handler to the delegate
        -- @usage   obj.OnEvent = obj.OnEvent + func
        function __add(self, func)
            if type(func) ~= "function" then error("Usage: (Delegate + func) - the func must be a function", 2) end

            if Attribute.HaveRegisteredAttributes() then
                local owner     = self.Owner
                local name      = self.Name

                Attribute.SaveAttributes(func, AttributeTargets.Function, 2)
                local ret = Attribute.InitDefinition(func, AttributeTargets.Function, func, owner, name, 2)
                if ret ~= func then
                    Attribute.ToggleTarget(func, ret)
                    func = ret
                end
                Attribute.ApplyAttributes (func, AttributeTargets.Function, owner, name, 2)
                Attribute.AttachAttributes(func, AttributeTargets.Function, owner, name, 2)
            end

            for _, f in ipairs, self, 0 do
                if f == ret then return self end
            end

            tinsert(self, ret)
            OnChange(self)
            return self
        end

        --- Use to remove stackable handler from the delegate
        -- @usage   obj.OnEvent = obj.OnEvent - func
        function __sub(self, func)
            for i, f in ipairs, self, 0 do
                if f == func then
                    tremove(self, i)
                    OnChange(self)
                    break
                end
            end
            return self
        end

        export { Delegate }
    end)

    --- Wrap the target function within the given function like pcall
    __Sealed__() __Final__()
    class "System.__Delegate__" (function(_ENV)
        extend "IInitAttribtue"

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- modify the target's definition
        -- @param   target                      the target
        -- @param   targettype                  the target type
        -- @param   definition                  the target's definition
        -- @param   owner                       the target's owner
        -- @param   name                        the target's name in the owner
        -- @param   stack                       the stack level
        -- @return  definition                  the new definition
        function InitDefinition(self, target, targettype, definition, owner, name, stack)
            local wrap          = self[1]
            return function(...) return wrap(target, ...) end
        end

        -----------------------------------------------------------
        --                       property                       --
        -----------------------------------------------------------
        --- the attribute target
        property "AttributeTarget"  { type = AttributeTargets,  default = AttributeTargets.Method + AttributeTargets.Function }

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__ { Function }
        function __new(func) return { func } end
    end)

    --- Represents errors that occur during application execution
    __Sealed__()
    Exception = class "System.Exception"(function(_ENV)
        -----------------------------------------------------------
        --                       property                       --
        -----------------------------------------------------------
        --- a message that describes the current exception
        property "Message"          { type = String }

        --- a string representation of the immediate frames on the call stack
        property "StackTrace"       { type = String }

        --- the method that throws the current exception
        property "TargetSite"       { type = String }

        --- the source of the exception
        property "Source"           { type = String }

        --- the Exception instance that caused the current exception
        property "InnerException"   { type = Exception }

        --- key/value pairs that provide additional information about the exception
        property "Data"             { type = Table }

        --- key/value pairs of the local variable
        property "LocalVariables"   { type = Table }

        --- key/value pairs of the upvalues
        property "Upvalues"         { type = Table }

        --- whether the stack data is saved, the system will save the stack data
        -- if the value is false when the exception is thrown out
        property "StackDataSaved"   { type = Boolean,       default = not Platform.EXCEPTION_SAVE_STACK_DATA }

        --- the stack level to be scanned, default 1, where the throw is called
        property "StackLevel"       { type = NaturalNumber, default = 1 }

        --- whether save the local variables and the upvalues for the exception
        property "SaveVariables"    { type = Boolean,       default = false }

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__{ String, Variable(Exception, true), Variable(Boolean, true) }
        function Exception(self, message, inner, savevariables)
            self.Message        = message
            self.InnerException = inner
            self.SaveVariables  = savevariables
        end

        -----------------------------------------------------------
        --                      meta-method                      --
        -----------------------------------------------------------
        function __tostring(self) return self.Message end
    end)

    --- Represents the tree containers for codes, it's the recommended
    -- environment for coding with PLoop
    __Sealed__()
    Module = class (_PLoopEnv, "System.Module") (function(_ENV)

        -----------------------------------------------------------
        --                        storage                        --
        -----------------------------------------------------------

        -----------------------------------------------------------
        --                        constant                       --
        -----------------------------------------------------------

        -----------------------------------------------------------
        --                        helpers                        --
        -----------------------------------------------------------

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------

        -----------------------------------------------------------
        --                       property                       --
        -----------------------------------------------------------


        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------

        -----------------------------------------------------------
        --                      meta-method                      --
        -----------------------------------------------------------
    end)
end

-------------------------------------------------------------------------------
--                              _G installation                              --
-------------------------------------------------------------------------------
do
    -----------------------------------------------------------------------
    --                            _G keyword                             --
    -----------------------------------------------------------------------
    _G.namespace                = _G.namespace  or namespace
    _G.import                   = _G.import     or import
    _G.enum                     = _G.enum       or enum
    _G.struct                   = _G.struct     or struct
    _G.class                    = _G.class      or class
    _G.interface                = _G.interface  or interface
    _G.Module                   = _G.Module     or Module

    -----------------------------------------------------------------------
    --                             Must Have                             --
    -----------------------------------------------------------------------
    _G.PLoop                    = ROOT_NAMESPACE
end

return ROOT_NAMESPACE