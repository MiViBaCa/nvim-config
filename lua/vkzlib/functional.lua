local MODULE = "functional"

local internal = require("vkzlib.internal")
local core = internal.core
local list = internal.list
local typing = internal.typing

local get_qualified_name = internal.get_qualified_name(MODULE)
local errmsg = internal.errmsg(MODULE)
local assert = internal.assert

local log = {
  d = internal.logger(MODULE, "debug"),
  t = internal.logger(MODULE, "trace"),
}

---@class Function
---@field private _raw function Original `function`
---@field private _value function Wrapped `function`
---@field private _argc integer Parameter count of wrapped `function`
---@field private _isvararg boolean Whether wrapped `function` has variadic argument
---@operator call(...): ...
Function = {}

---If `x` is an valid `Function` object
---@param x any
---@return boolean
Function.is_function_object = function (x)
  -- FIX I think this wouldn't be true for subclasses (Inheritance implementation from PiL 16.2)
  return getmetatable(x).__index == Function
end

---@class Function.new.Params
---@field [1] function
---@field argc integer?
---@field isvararg boolean?
---@field raw function?

---Create `Function` object from `f`
---@param params? Function.new.Params
---@return Function
---
---@see Function.new.Params
---@see Function
function Function:new(params)
  assert(params ~= nil and type(params) == "table", function()
    return errmsg("Function:new", "This function receive table as argument")
  end)
  ---@type function
  local f = params[1]
  assert(f ~= nil and type(f) == "function", function()
    return errmsg("Function:new", "1st argument not a function")
  end)
  ---@type integer?
  local argc = params.argc
  assert(argc == nil or type(argc) == "number", function()
    return errmsg("Function:new", "Invalid opts.argc")
  end)
  ---@type boolean?
  local isvararg = params.isvararg
  assert(isvararg == nil or type(isvararg) == "boolean", function()
    return errmsg("Function:new", "Invalid opts.isvararg")
  end)
  ---@type function?
  local raw = params.raw
  assert(raw == nil or type(raw) == "function", function()
    return errmsg("Function:new", "Invalid opts.raw")
  end)
  local info = debug.getinfo(f, "u")
  assert(argc == nil or argc >= info.nparams, function ()
    return errmsg("Function:new", string.format(
      "`opts.argc` bigger then parameter count of wrapped `function` (%i : %i)",
      argc,
      info.nparams
    ))
  end)

  if isvararg == nil then
    isvararg = info.isvararg
  end
  ---@type Function
  local res = {
    _raw = raw or f,
    _value = f,
    _argc = argc or info.nparams,
    _isvararg = isvararg,
  }
  -- This method should easily implement inheritance
  -- Literally use self (class object) as meta table
  -- But seems complicated to implement operator overload

  -- Make callable
  -- !!! This fucked up because this will override call operator for all objects every time you instantiate an object
  -- self.__call = function (_, ...)
  --   return f(...)
  -- end

  -- Make colon call search method in class object
  -- self.__index = self

  -- setmetatable(res, self)


  setmetatable(res, {
    -- Overload call operator for instance
    __call = function (_, ...)
      return f(...)
    end,
    -- Make colon call search method in class object
    __index = self
  })

  log.t("Function:new", "Object created", res)
  return res
end

---Copy function object
---@param noref boolean
function Function:copy(noref)
  assert(Function.is_function_object(self), function() return
    errmsg("Function:copy", "not a `Function`")
  end)
  return core.copy(self, noref)
end

---@class Function.constructor.Params
---@field [1] function | Function
---@field argc integer?
---@field isvararg boolean?
---@field raw function?
---@field noref boolean?
---
---@see Function:new.Params
---@see Function.copy

setmetatable(Function, {
  ---Constructor overload
  ---@param opts Function.constructor.Params
  ---
  ---@see Function.constructor.Params
  __call = function (_, opts)
    assert(type(opts) == "table", function()
      return errmsg("Function.constructor", "This function receive `table` as argument")
    end)
    local f = opts[1]
    if typing.is_type(f, "function") then
      ---@cast f function
      return Function:new { f,
        argc = opts.argc,
        isvararg = opts.isvararg,
        raw = opts.raw
      }
    elseif Function.is_function_object(f) then
      ---@cast f Function
      return f:copy(opts.noref)
    else
      error(errmsg("Function.constructor", "1st argument not a `function` or `Function`"))
    end
  end
})

function Function:get()
  assert(type(self._value) == "function")
  return self._value
end

function Function:get_raw()
  assert(type(self._raw) == "function")
  return self._raw
end

function Function:get_argc()
  assert(type(self._argc) == 'number')
  return self._argc
end

function Function:is_vararg()
  assert(type(self._isvararg) == "boolean")
  return self._isvararg
end

function Function:apply(...)
  assert(select("#", ...) >= self._argc, function()
    return errmsg("Function:apply", "require more arguments")
  end)
  return self(...)
end

---Identity function that simply return argument itself
---@param x any
---@return any
local function id(x)
  return x
end

---Add an argument in front and discard it
---@param f function | Function
---@return Function
local function to_const(f)
  local function _to_const(_f)
    return function (_, ...)
      return _f(...)
    end
  end
  if type(f) == "function" then
    local info = debug.getinfo(f)
    return Function:new { _to_const(f),
      argc = info.nparams + 1,
    }
  end
  assert(Function.is_function_object(f), function()
    return errmsg("to_const", "not a valid function object")
  end)
  return Function { _to_const(f:get()),
    argc = Function.get_argc(f) + 1,
    isvararg = Function.is_vararg(f),
    raw = Function.get_raw(f)
  }
end

---Currying `f` with `argc`
---@param f Function
---@return Function
local function _curry(f)
  assert(Function.is_function_object(f))

  local function curried(...)
    local argv = list.pack(...)
    log.t("_curry.curried", "All args", argv)
    if argv.n >= f:get_argc() then
      log.t("_curry.curried", "Finalized", string.format("%i = argv.n >= f:get_argc() = %i", argv.n, f:get_argc()))
      return Function:new {
        function ()
          return f(list.unpack(argv))
        end
      }
    end

    return Function:new {
      function (...)
        local storedArgs = { list.unpack(argv) }
        local newArgs = list.pack(...)
        log.t("_curry.curried.return", "New args", newArgs)
        for i = 1, newArgs.n do
          table.insert(storedArgs, newArgs[i])
        end
        return curried(list.unpack(storedArgs))
      end,
      argc = Function.get_argc(f) - argv.n
    }
  end

  return curried()
end

---Currying function `f` with optional argument count
---By default, `maxArgc` is the number of arguments `f` expect
---Variadic function must provide argc
---@param f function | Function
---@param argc integer?
---@return Function
local function curry(f, argc)
  -- TODO Refactor
  local nparams = nil
  local opts = {}
  if type(f) == "function" then
    local info = debug.getinfo(f)
    opts.isvararg = info.isvararg
    if not opts.isvararg then
      -- Not vararg, retrieve anything
      argc = core.from_maybe(info.nparams, argc)
      assert(argc >= 0 and argc <= info.nparams, function()
        return errmsg("curry", "argc out of range")
      end)
    else
      -- If isvararg, leave argc untouched
      -- Let caller decide how many arguments it takes
      -- But argc must greater or equal than minimal requirement
      assert(type(argc) == "number", function()
        return errmsg("curry", "argc is required for vararg function")
      end)
      assert(argc >= info.nparams, function()
        return errmsg("curry", "argc less than minimal requirement")
      end)
    end
  elseif Function.is_function_object(f) then
    -- Almost the same
    opts.isvararg = Function.is_vararg(f)
    if not opts.isvararg then
      argc = core.from_maybe(Function.get_argc(f), argc)
      assert(argc >= 0 and argc <= Function.get_argc(f), function()
        return errmsg("curry", "argc out of range")
      end)
    else
      assert(type(argc) == "number", function()
        return errmsg("curry", "argc is required for vararg function")
      end)
      assert(argc >= Function.get_argc(f), function()
        return errmsg("curry", "argc less than minimal requirement")
      end)
    end
  else
    error(errmsg("curry", "Not a callable"))
  end

  -- TODO Use argc
  -- Actually, figure out what argc does first
  f = Function { f, opts.isvararg }

  log.t("curry", "Object passed to _curry", f)

  return _curry(f)
end

-- TODO `Function` compatibility
-- TODO Use weak table for nparams = 1
-- TODO Expand nparams for positive integer by recursively apply nparams = 1 to decrease nparams
---Make function `f` memorize its result
---@param f function
---@return function
local function memorize(f)
  assert(type(f) == "function" and debug.getinfo(f, "u").nparams == 0, function()
    return errmsg("memorize", "only function with no argument can be memorized")
  end)
  local function closure()
    local mem = nil
    return function ()
      if mem ~= nil then
        log.t("memorize", "skipped")
        if _DEBUG then
          return mem, true
        end
        return mem
      end
      mem = f()
      if _DEBUG then
        return mem, false
      end
      return mem
    end

  end

  return closure()
end

-- TODO `Function` compatibility
---Apply arguments to function `f`
---@param f function
---@param ... any
---@return any
local function apply(f, ...)
  assert(type(f) == "function", function()
    return errmsg("apply", "not a function")
  end)
  return f(...)
end

-- TODO `Function` compatibility
---Compose two functions
---@param f function
---@param g function
---@return function
local function compose(f, g)
  return function (x, ...)
    return f(g(x), ...)
  end
end

-- TODO `Function` compatibility
---Swap position of first and second argument
---@param f function
---@return function
local function flip(f)
  return function (y, x, ...)
    return f(x, y, ...)
  end
end

return {
  Function = Function,

  id = id,
  to_const = to_const,
  curry = curry,
  apply = apply,
  compose = compose,
  flip = flip,
  memorize = memorize,
}

