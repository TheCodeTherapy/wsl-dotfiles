local M = {}

function M.chatgpt_request(api_key, system_prompt, user_prompt, output_file)
  local payload = {
    model = "gpt-4",
    messages = {
      { role = "system", content = system_prompt },
      { role = "user", content = user_prompt },
    },
    max_tokens = 1500,
    temperature = 0.7,
    stream = true,
  }

  local payload_json = vim.fn.json_encode(payload)

  -- Use curl with the --no-buffer option to stream the response in real-time
  local curl_command = string.format(
    "curl -s --no-buffer -X POST https://api.openai.com/v1/chat/completions "
      .. '-H "Content-Type: application/json" '
      .. '-H "Authorization: Bearer %s" '
      .. "-d '%s'",
    api_key,
    payload_json
  )

  -- Hide the input box after receiving the input
  vim.defer_fn(function()
    vim.cmd("normal :q<CR>")
  end, 100)

  -- Create a new buffer for the markdown file
  vim.cmd("enew")
  vim.cmd("setlocal buftype=nofile")
  vim.cmd("setlocal bufhidden=hide")
  vim.cmd("setlocal noswapfile")

  -- Save the buffer immediately as the markdown file (overwriting if necessary)
  vim.cmd("silent! w! " .. output_file)
  vim.cmd("e " .. output_file)

  -- Start the MarkdownPreview
  vim.cmd("MarkdownPreview")

  -- Start the streaming process
  local handle = io.popen(curl_command)
  if handle then
    local current_line = "" -- Accumulate content to be finalized
    local display_line = "" -- Manage what's displayed in the buffer

    for line in handle:lines() do
      if line:find("data: ") then
        local json_str = line:gsub("data: ", "")
        if json_str ~= "[DONE]" then
          local chunk_data = vim.fn.json_decode(json_str)
          if chunk_data and chunk_data.choices then
            for _, choice in ipairs(chunk_data.choices) do
              local content = choice.delta.content or ""

              -- Accumulate the current line and display line
              current_line = current_line .. content
              display_line = display_line .. content

              -- Check if the content contains a newline
              if display_line:find("\n") then
                local lines = {}
                for subline in display_line:gmatch("([^\n]*)\n?") do
                  table.insert(lines, subline)
                end

                -- Write the completed line to the buffer
                local line_count = vim.api.nvim_buf_line_count(0)
                vim.api.nvim_buf_set_lines(0, line_count - 1, line_count, false, { lines[1] })
                vim.cmd("redraw")

                -- Start a new line for the rest of the content
                if #lines > 1 then
                  for i = 2, #lines do
                    vim.api.nvim_buf_set_lines(0, -1, -1, false, { lines[i] })
                  end
                  vim.cmd("w!")
                end

                display_line = "" -- Reset display_line for new content
              else
                -- Update the current line in the buffer
                local line_count = vim.api.nvim_buf_line_count(0)
                vim.api.nvim_buf_set_lines(0, line_count - 1, line_count, false, { display_line })
                vim.cmd("redraw")
              end
            end
          end
        end
      end
    end

    -- Final buffer update with any remaining content
    if display_line ~= "" then
      local line_count = vim.api.nvim_buf_line_count(0)
      vim.api.nvim_buf_set_lines(0, line_count - 1, line_count, false, { display_line })
    end

    -- Save the final state of the file
    vim.cmd("w!")

    -- Close the handle
    handle:close()

    print("Stream finished 🤓")
  else
    print("Error: Failed to execute curl command")
  end
end

return M
