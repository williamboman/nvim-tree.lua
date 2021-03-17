local api = vim.api
local luv = vim.loop

local lib = require'nvim-tree.lib'
local config = require'nvim-tree.config'
local colors = require'nvim-tree.colors'
local renderer = require'nvim-tree.renderer'
local fs = require'nvim-tree.fs'
local utils = require'nvim-tree.utils'
local layout = require'nvim-tree.layout'

local M = {}

function M.toggle()
  if layout.is_win_open() then
    layout.win_close()
  else
    layout.win_open()
    if vim.g.nvim_tree_follow == 1 then
      vim.schedule(function() M.find_file(true) end)
    end
  end
end

function M.close()
  layout.win_close()
  return true
end

function M.open(cb)
  vim.schedule(
    function()
      if not layout.is_win_open() then
        layout.win_open()
        if not lib.loaded then
          lib.init()
        end
      else
        lib.set_target_win()
      end
      pcall(cb)
    end
  )
end

local function gen_go_to(mode)
  local icon_state = config.get_icon_state()
  local flags = mode == 'prev_git_item' and 'b' or ''
  local icons = table.concat(vim.tbl_values(icon_state.icons.git_icons), '\\|')
  return function()
    return icon_state.show_git_icon and vim.fn.search(icons, flags)
  end
end

local keypress_funcs = {
  create = fs.create,
  remove = fs.remove,
  rename = fs.rename(false),
  full_rename = fs.rename(true),
  copy = fs.copy,
  cut = fs.cut,
  paste = fs.paste,
  close_node = lib.close_node,
  toggle_ignored = lib.toggle_ignored,
  toggle_dotfiles = lib.toggle_dotfiles,
  refresh = lib.refresh_tree,
  prev_git_item = gen_go_to('prev_git_item'),
  next_git_item = gen_go_to('next_git_item'),
  dir_up = lib.dir_up,
  close = function(node) M.close() end,
  preview = function(node)
    if node.entries ~= nil or node.name == '..' then return end
    return lib.open_file('preview', node.absolute_path)
  end,
}

function M.on_keypress(mode)
  local node = lib.get_node_at_cursor()
  if not node then return end

  if keypress_funcs[mode] then
    return keypress_funcs[mode](node)
  end

  if node.name == ".." then
    return lib.change_dir("..")
  elseif mode == "cd" and node.entries ~= nil then
    return lib.change_dir(node.absolute_path)
  elseif mode == "cd" then
    return
  end

  if node.link_to and not node.entries then
    lib.open_file(mode, node.link_to)
  elseif node.entries ~= nil then
    lib.unroll_dir(node)
  else
    lib.open_file(mode, node.absolute_path)
  end
end

function M.refresh()
  lib.refresh_tree()
end

function M.print_clipboard()
  fs.print_clipboard()
end

function M.on_enter()
  local bufnr = api.nvim_get_current_buf()
  local bufname = api.nvim_buf_get_name(bufnr)
  local buftype = api.nvim_buf_get_option(bufnr, 'filetype')
  local ft_ignore = vim.g.nvim_tree_auto_ignore_ft or {}

  local stats = luv.fs_stat(bufname)
  local is_dir = stats and stats.type == 'directory'

  local disable_netrw = vim.g.nvim_tree_disable_netrw or 1
  local hijack_netrw = vim.g.nvim_tree_hijack_netrw or 1
  if is_dir then
    api.nvim_command('cd '..bufname)
  end
  local should_open = vim.g.nvim_tree_auto_open == 1
    and ((is_dir and (hijack_netrw == 1 or disable_netrw == 1)) or bufname == '')
    and not vim.tbl_contains(ft_ignore, buftype)
  lib.init(should_open, should_open)
end

local function is_file_readable(fname)
  local stat = luv.fs_stat(fname)
  if not stat or not stat.type == 'file' or not luv.fs_access(fname, 'R') then return false end
  return true
end

function M.find_file(with_open)
  local bufname = vim.fn.bufname()
  local filepath = vim.fn.fnamemodify(bufname, ':p')

  if with_open then
    return M.open(
      function()
        layout.win_focus()
        if not is_file_readable(filepath) then return end
        lib.set_index_and_redraw(filepath)
      end
    )
  end

  if not is_file_readable(filepath) then return end
  lib.set_index_and_redraw(filepath)
end

function M.on_leave()
  vim.defer_fn(function()
    if #api.nvim_list_wins() == 1 and lib.win_open() then
      api.nvim_command(':silent qa!')
    end
  end, 50)
end

local function update_root_dir()
  local bufname = api.nvim_buf_get_name(api.nvim_get_current_buf())
  if not is_file_readable(bufname) or not lib.Tree.cwd then return end

  -- this logic is a hack
  -- depending on vim-rooter or autochdir, it would not behave the same way when those two are not enabled
  -- until i implement multiple workspaces/project, it should stay like this
  if bufname:match(utils.path_to_matching_str(lib.Tree.cwd)) then
    return
  end
  local new_cwd = luv.cwd()
  if lib.Tree.cwd == new_cwd then return end

  lib.change_dir(new_cwd)
end

function M.buf_enter()
  update_root_dir()
  if vim.g.nvim_tree_follow == 1 then
    M.find_file(false)
  end
end

function M.reset_highlight()
  colors.setup()
  renderer.render_hl(lib.Tree.bufnr)
end

function M.setup(opts)
  layout.setup {
    keep_size = opts.keep_size or false,
    keep_open = opts.keep_open or false,
    side = opts.side or 'left',
    size = opts.size or 30,
    disable_keymaps = opts.disable_keymaps or false,
    keymaps = opts.keymaps or {}
  }
  layout.buf_create()
  colors.setup()
  if opts.open_on_setup then
    layout.win_open()
    lib.init()
  end
end

return M
