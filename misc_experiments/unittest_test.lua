-------------------------------------------------------------------------------
-- UNIT TEST - uhh test
-- 
-- Testing possible LUA unit test methods.
--
-- GPG - 20150604
-------------------------------------------------------------------------------

luaunit = require('luaunit')

-------------------------------------------------------------------------------
--
function my_function(arg1, arg2) return arg1 + arg2 end

-------------------------------------------------------------------------------
--
function add(v1,v2)
    -- add positive numbers
    -- return 0 if any of the numbers are 0
    -- error if any of the two numbers are negative
    if v1 < 0 or v2 < 0 then
        error('Can only add positive or null numbers, received '..v1..' and '..v2)
    end
    if v1 == 0 or v2 == 0 then
        return 0
    end
    return v1+v2
end

function adder(v)
    -- return a function that adds v to its argument using add
    function closure( x ) return x+v end
    return closure
end

-------------------------------------------------------------------------------
--
function div(v1,v2)
    -- divide positive numbers
    -- return 0 if any of the numbers are 0
    -- error if any of the two numbers are negative
    if v1 < 0 or v2 < 0 then
        error('Can only divide positive or null numbers, received '..v1..' and '..v2)
    end
    if v1 == 0 or v2 == 0 then
        return 0
    end
    return v1/v2
end

-------------------------------------------------------------------------------
-- error function test
function ast(v1, v2)
	assert(v1 ~= nil, "V1 is nil.")
	assert(v2 ~= nil, "V2 is nil.")

	return ("V1 = " .. v1 .. " V2 = " .. v2)
end

-------------------------------------------------------------------------------
--
local g_logName
function initLog(name)
	if (name == nil or name == "") then error("The log must have a name.") end
	g_logName = name
end

-------------------------------------------------------------------------------
--
function log(message)
	if (g_logName == nil or g_logName == "") then error("You must call initLog and define a log file name first.") end
		f = assert(io.open(g_logName, "a"))
		f:write(message .. "\n")
		f:close()
end

-------------------------------------------------------------------------------
--													The Test Definitions 
-------------------------------------------------------------------------------

TestAdd = {}
    function TestAdd:testAddPositive()
        luaunit.assertEquals(add(1,1),2)
    end

    function TestAdd:testAddZero()
        luaunit.assertEquals(add(1,0),0)
        luaunit.assertEquals(add(0,5),0)
        luaunit.assertEquals(add(0,0),0)
    end

    function TestAdd:testAddError()
        luaunit.assertErrorMsgContains('Can only add positive or null numbers, received 2 and -3', add, 2, -3)
    end

    function TestAdd:testAdder()
        f = adder(3)
        luaunit.assertIsFunction( f )
        luaunit.assertEquals( f(2), 5 )
    end
-- end of table TestAdd

TestDiv = {}
    function TestDiv:testDivPositive()
        luaunit.assertEquals(div(4,2),2)
    end

    function TestDiv:testDivZero()
        luaunit.assertEquals(div(4,0),0)
        luaunit.assertEquals(div(0,5),0)
        luaunit.assertEquals(div(0,0),0)
    end

    function TestDiv:testDivError()
        luaunit.assertErrorMsgContains('Can only divide positive or null numbers, received 2 and -3', div, 2, -3)
    end
-- end of table TestDiv

TestAst = {}
	function TestAst:testCorrectCall()
		luaunit.assertEquals(ast("Bob", "Bill"), "V1 = Bob V2 = Bill" )
	end
	
	function TestAst:testCallWithEmptyString()
		luaunit.assertEquals(ast("Bob", ""), "V1 = Bob V2 = " )
	end
	
	function TestAst:testInvalidCall()
		luaunit.assertError(ast, "Bob")
	end
-- end of TestAst


TestLogger = {}
	function TestLogger:setUp()
		-- define the fname to use for logging
		self.fname = 'mytmplog.log'
		-- make sure the file does not already exists
		os.remove(self.fname)
	end
	
	function TestLogger:testInitWithoutFilename()
		luaunit.assertError(initLog, "")
	end
	
	function TestLogger:testLogWithoutInit()
		luaunit.assertError(log, "Message")
	end

	function TestLogger:testLoggerCreatesFile()
		initLog(self.fname)
		log('toto')
		-- make sure that our log file was created
		f = io.open(self.fname, 'r')
		luaunit.assertNotNil( f )
		f:close()
	end

	function TestLogger:tearDown()
		-- cleanup our log file after all tests
		os.remove(self.fname)
	end


TestMyStuff = {} -- class
	function TestMyStuff:testWithNumbers()
		a = 1
		b = 2
		result = my_function(a, b)
		luaunit.assertEquals(type(result), 'number')
		luaunit.assertEquals(result, 3)
	end
	
	function TestMyStuff:testWithRealNumber()
		a = 1.1
		b = 2.2
		result = my_function(a, b)
		luaunit.assertEquals(type(result), 'number')
		luaunit.assertEquals(tostring(result), tostring(3.3))
	end
	
	function TestMyStuff:testIsTable()
		local tbl = { 1, 2, 3, 4, 5 } 
		
		luaunit.assertIsTable(tbl)
	end
	
-- class TestMyStuff

-------------------------------------------------------------------------------
-- 																	Main 
-------------------------------------------------------------------------------

print("\n\nDo some other stuff here")
print("\n\nNow run some unit tests ... \n\n")

os.exit(luaunit.LuaUnit.run())
