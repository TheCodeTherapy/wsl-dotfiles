local chatgpt = require("plugins.gpt.chatgpt")
local repo_info_generator = require("plugins.gpt.repo_info")

-- Function to create and handle a multi-line input floating window
local function get_user_input(prompt_text, callback)
  -- Create a new buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile" -- Set buffer type to nofile instead of prompt
  -- Define the window border and position
  local width = math.floor(vim.o.columns * 0.5)
  local height = 5
  local opts = {
    style = "minimal",
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    border = "rounded",
  }

  -- Create the floating window
  local win = vim.api.nvim_open_win(buf, true, opts)

  -- Set a prompt in the window
  vim.fn.prompt_setprompt(buf, prompt_text .. "\n")

  -- Function to close the window and return the input
  local function close_window_and_return_input()
    local input = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")

    -- Clean the input by removing null characters or any unexpected characters
    input = input:gsub("%z", "") -- Removes any null characters
    vim.api.nvim_win_close(win, true)
    vim.api.nvim_buf_delete(buf, { force = true })

    if callback then
      callback(input)
    end
  end

  -- Configure key mappings for the buffer
  vim.api.nvim_buf_set_keymap(buf, "i", "<CR>", "", {
    noremap = true,
    silent = true,
    callback = close_window_and_return_input,
  })
  vim.api.nvim_buf_set_keymap(buf, "n", "<CR>", "", {
    noremap = true,
    silent = true,
    callback = close_window_and_return_input,
  })

  vim.opt_local.wrap = true

  -- Start insert mode in the floating window
  vim.cmd("startinsert")
end

local function save_gpt_last_request(system_prompt, user_input)
  local timestamp = os.date("%Y-%m-%d %H:%M:%S")
  local last_request_file = "gpt_response.md"
  last_request_file = vim.fn.fnamemodify(last_request_file, ":h") .. "/.gpt_last_request.md"

  local file = io.open(last_request_file, "w")
  if file then
    file:write("# GPT Last Request\n\n")
    file:write("**Timestamp:** " .. timestamp .. "\n\n")
    file:write("**System Prompt:**\n\n" .. system_prompt .. "\n\n")
    file:write("**User Input:**\n\n" .. user_input .. "\n\n")
    file:close()
    print("GPT last request saved to " .. last_request_file)
  else
    print("Error: Failed to write .gpt_last_request.md")
  end
end

-- Command to trigger the GPT request with the multi-line input window
vim.api.nvim_create_user_command("GPT", function()
  local api_key = os.getenv("OPENAI_API_KEY")
  if not api_key then
    print("Error: OPENAI_API_KEY is not set.")
    return
  end

  get_user_input("User Prompt:", function(user_input)
    if user_input and user_input:gsub("%s+", "") ~= "" then
      local repo_info = repo_info_generator.generate_repo_info()
      if not repo_info then
        print("Error: Failed to generate repo info")
        return
      else
        local repo_info_content = io.open(repo_info, "r"):read("*a")
        local system_prompt = "You are a helpful assistant."
        system_prompt = system_prompt .. "Always answer in a markdown format."
        system_prompt = system_prompt
          .. "When writing code, please keep in mind to properly set the markdown for the appropriate syntax highlight."
        system_prompt = system_prompt .. repo_info_content
        save_gpt_last_request(system_prompt, user_input)
        chatgpt.chatgpt_request(api_key, system_prompt, user_input, "gpt_response.md")
        -- vim.cmd("e gpt_response.md")
      end
    else
      print("Input was canceled or empty")
    end
  end)
end, {})

return {}
