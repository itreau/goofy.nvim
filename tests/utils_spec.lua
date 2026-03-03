describe("utils", function()
  local utils
  
  before_each(function()
    package.loaded["goofy.utils"] = nil
    _G.vim = require("tests.mock_vim")
    utils = require("goofy.utils")
  end)
  
  describe("normalize_frame", function()
    it("returns array unchanged when already an array", function()
      local input = { "line1", "line2", "line3" }
      local result = utils.normalize_frame(input)
      assert.are.same(input, result)
    end)
    
    it("converts heredoc string to array of lines", function()
      local input = [[line1
line2
line3]]
      local result = utils.normalize_frame(input)
      assert.are.same({ "line1", "line2", "line3" }, result)
    end)
    
    it("handles single line heredoc", function()
      local input = "single line"
      local result = utils.normalize_frame(input)
      assert.are.same({ "single line" }, result)
    end)
    
    it("strips carriage returns from lines", function()
      local input = "line1\r\nline2\r\nline3"
      local result = utils.normalize_frame(input)
      assert.are.same({ "line1", "line2", "line3" }, result)
    end)
    
    it("returns empty array for empty string", function()
      local input = ""
      local result = utils.normalize_frame(input)
      assert.are.same({ "" }, result)
    end)
    
    it("preserves whitespace in lines", function()
      local input = [[  line1  
	line2	]]
      local result = utils.normalize_frame(input)
      assert.are.same({ "  line1  ", "\tline2\t" }, result)
    end)
  end)
end)
