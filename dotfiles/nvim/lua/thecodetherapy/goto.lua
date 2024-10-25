local M = {}

M.go_to_implementation = function()
  local current_file = vim.fn.expand("%:p")
  print("Definition: ", current_file)
  if current_file:match("%.d%.ts") then
    local src_file = current_file:gsub("build", "src"):gsub("%.d%.ts$", ".ts")
    print("Source: ", src_file)
    if vim.fn.filereadable(src_file) == 1 then
      vim.cmd("edit " .. src_file)
    else
      print("falling back to definition")
      vim.lsp.buf.definition()
    end
  end
end

return M
