local M = {}

local function generate_repo_info()
  local dir = vim.fn.getcwd() -- Get the current working directory (project root)
  local info_file = dir .. "/.repoinfo.md"

  -- Run the 'tree' command and capture the output
  local handle = io.popen("tree -q --noreport -L 2 -I '*.json|deps|build'")

  if not handle then
    print("Error: Failed to execute the tree command")
    return nil
  end

  local tree_output = handle:read("*a")
  handle:close()

  if not tree_output then
    print("Error: Failed to read tree output")
    return nil
  end

  -- Define a table with non-standard space characters
  local non_standard_spaces = {
    "\xC2\xA0", -- Non-breaking space
    "\xE2\x80\x80", -- En quad
    "\xE2\x80\x81", -- Em quad
    "\xE2\x80\x82", -- En space
    "\xE2\x80\x83", -- Em space
    "\xE2\x80\x84", -- Three-per-em space
    "\xE2\x80\x85", -- Four-per-em space
    "\xE2\x80\x86", -- Six-per-em space
    "\xE2\x80\x87", -- Figure space
    "\xE2\x80\x88", -- Punctuation space
    "\xE2\x80\x89", -- Thin space
    "\xE2\x80\x8A", -- Hair space
    "\xE2\x80\xAF", -- Narrow no-break space
    "\xE2\x81\x9F", -- Medium mathematical space
    "\xE3\x80\x80", -- Ideographic space
  }

  -- Replace non-standard spaces with regular spaces
  for _, space in ipairs(non_standard_spaces) do
    tree_output = tree_output:gsub(space, " ")
  end

  -- Open the info file for writing
  local file = io.open(info_file, "w")
  if not file then
    print("Error: Failed to open info file for writing")
    return nil
  end

  file:write("The basic structure of the app is as follows:\n```\n")
  file:write(tree_output .. "\n```\n")

  -- Define an array of ignored file prefixes
  local ignored_files = {}

  -- Extensions to search for
  local extensions = { "*.cpp", "*.hpp", "*.c", "*.h", "*.js", "*.ts", "*.tsx", "*.lua", "*.sh", "*.py" }

  -- Append contents of the specified file extensions from the src folder to the info file, excluding ignored files
  for _, ext in ipairs(extensions) do
    local src_files = vim.fn.globpath(dir .. "/src", "**/" .. ext, false, true)
    for _, filepath in ipairs(src_files) do
      local basename = vim.fn.fnamemodify(filepath, ":t")
      local ignore = false

      for _, prefix in ipairs(ignored_files) do
        if basename:find("^" .. prefix) then
          ignore = true
          break
        end
      end

      if not ignore then
        file:write("\n" .. basename .. ":\n```\n")
        local content_file = io.open(filepath, "r")
        if content_file then
          local content = content_file:read("*a")
          content_file:close()

          if content then
            file:write(content)
          else
            print("Warning: Failed to read content from " .. filepath)
          end
        else
          print("Warning: Failed to open " .. filepath)
        end
        file:write("\n```\n")
      end
    end
  end

  file:close()

  -- Open the .repoinfo.md file in a new buffer after writing it
  -- vim.cmd("edit " .. info_file)

  return info_file
end

M.generate_repo_info = generate_repo_info

vim.api.nvim_create_user_command("GenerateRepoInfo", function()
  generate_repo_info()
end, {})

return M
