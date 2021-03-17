-- this file handles buffer, window and tab management
local a = vim.api
local cmd = vim.cmd

local M = {
  tabpages = {};
  bufnr = nil;
  bufname = 'NvimTree';
  keep_size = false;
  keep_open = false;
  side = 'left';
  size = 30;
  disable_keymaps = false;
  buf_opts = {
    bufhidden = 'hide';
    buftype = 'nofile';
    modifiable = false;
    filetype = 'NvimTree';
    swapfile = false,

  };
  win_opts = {
    winhl = 'EndOfBuffer:NvimTreeEndOfBuffer,Normal:NvimTreeNormal,CursorLine:NvimTreeCursorLine,VertSplit:NvimTreeVertSplit';
    relativenumber = false,
    number = false,
    list = false,
    winfixwidth = true,
    winfixheight = true,
    foldenable = false,
    spell = false,
    signcolumn = 'yes',
    foldmethod = 'manual',
    foldcolumn = '0'
  };
  keymaps = {};
}

function M.nvim_tree_callback(callback_name)
  return string.format(":lua require'nvim-tree'.on_keypress('%s')<CR>", callback_name)
end

local keymaps = {
  ["<CR>"]           = M.nvim_tree_callback("edit"),
  ["o"]              = M.nvim_tree_callback("edit"),
  ["<2-LeftMouse>"]  = M.nvim_tree_callback("edit"),
  ["<2-RightMouse>"] = M.nvim_tree_callback("cd"),
  ["<C-]>"]          = M.nvim_tree_callback("cd"),
  ["<C-v>"]          = M.nvim_tree_callback("vsplit"),
  ["<C-x>"]          = M.nvim_tree_callback("split"),
  ["<C-t>"]          = M.nvim_tree_callback("tabnew"),
  ["<BS>"]           = M.nvim_tree_callback("close_node"),
  ["<S-CR>"]         = M.nvim_tree_callback("close_node"),
  ["<Tab>"]          = M.nvim_tree_callback("preview"),
  ["I"]              = M.nvim_tree_callback("toggle_ignored"),
  ["H"]              = M.nvim_tree_callback("toggle_dotfiles"),
  ["R"]              = M.nvim_tree_callback("refresh"),
  ["a"]              = M.nvim_tree_callback("create"),
  ["d"]              = M.nvim_tree_callback("remove"),
  ["r"]              = M.nvim_tree_callback("rename"),
  ["<C-r>"]          = M.nvim_tree_callback("full_rename"),
  ["x"]              = M.nvim_tree_callback("cut"),
  ["c"]              = M.nvim_tree_callback("copy"),
  ["p"]              = M.nvim_tree_callback("paste"),
  ["[c"]             = M.nvim_tree_callback("prev_git_item"),
  ["]c"]             = M.nvim_tree_callback("next_git_item"),
  ["-"]              = M.nvim_tree_callback("dir_up"),
  ["q"]              = M.nvim_tree_callback("close"),
}

function M.get_win()
  return M.tabpages[a.nvim_get_current_tabpage()]
end

local function set_win(win)
  M.tabpages[a.nvim_get_current_tabpage()] = win
end

function M.buf_restore()
  if M.is_win_open() then
    a.nvim_win_set_buf(M.winnr, M.bufnr)
  end
end

local function set_buf_keymaps()
  if M.disable_keymaps then return end

  for key, cb in pairs(M.keymaps) do
    a.nvim_buf_set_keymap(M.bufnr, 'n', key, cb, {
      nowait = true, noremap = true, silent = true
    })
  end
end

local function set_buf_options()
  for opt, val in pairs(M.buf_opts) do
    a.nvim_buf_set_option(M.bufnr, opt, val)
  end
end

function M.buf_create()
  M.bufnr = a.nvim_create_buf(false, true)
  a.nvim_buf_set_name(M.bufnr, M.bufname)

  set_buf_options()
  set_buf_keymaps()
end

function M.win_open()
  if M.is_win_open() then return end

  cmd "vsplit"
  cmd("wincmd "..(M.side == 'left' and 'H' or 'L'))

  local winnr = a.nvim_get_current_win()
  a.nvim_win_set_width(winnr, M.size)
  set_win(winnr)

  for name, value in pairs(M.win_opts) do
    a.nvim_win_set_option(winnr, name, value)
  end
  M.buf_restore()
end

function M.win_close()
  if not M.is_win_open() then return end

  a.nvim_win_close(M.get_win(), true)
  set_win(nil)
end

function M.is_win_open()
  return M.get_win() and a.nvim_win_is_valid(M.get_win())
end

function M.on_tab_change()
  if not M.keep_open then return end

  local is_open = false

  for tabpage in pairs(a.nvim_list_tabpages()) do
    if M.tabpages[tabpage] ~= nil and a.nvim_win_is_valid(M.tabpages[tabpage]) then
      is_open = true
      break
    end
  end

  if not is_open then return end

  M.win_open()
end

function M.on_resize()
  if not M.keep_size or not M.is_win_open() then return end

  local winnr = M.get_win()
  a.nvim_win_set_width(winnr, M.size)
end

-- keep_size = false | true
-- side = 'left' | 'right'
-- keep_open = false | true
-- size = 30
-- disable_keymaps = false
-- keymaps = table
function M.setup(opts)
  for k, opt in pairs(opts) do
    if k == 'keymaps' then
      M[k] = vim.tbl_extend('force', keymaps, opt)
    else
      M[k] = opt
    end
  end
end

function M.win_focus()
  if not M.is_win_open() then return end
  a.nvim_set_current_win(M.get_win())
end

return M
