if !has('nvim-0.5') || exists('g:loaded_tree') | finish | endif

let s:save_cpo = &cpo
set cpo&vim

if get(g:, 'nvim_tree_disable_netrw', 1) == 1
    let g:loaded_netrw = 1
    let g:loaded_netrwPlugin = 1
endif

augroup NvimTree
  if get(g:, 'nvim_tree_hijack_netrw', 1) == 1 && get(g:, 'nvim_tree_disable_netrw', 1) == 0
    autocmd! FileExplorer *
  endif

  " au BufWritePost * lua require'nvim-tree'.refresh()
  " au BufEnter * lua require'nvim-tree'.buf_enter()
  " au ColorScheme * lua require'nvim-tree'.reset_highlight()
  " au User FugitiveChanged lua require'nvim-tree'.refresh()

  " au WinClosed * lua require'nvim-tree'.on_leave()
  au TabEnter * lua require'nvim-tree.layout'.on_tab_change()
  au BufEnter * lua require'nvim-tree.layout'.on_resize()
augroup end

command! NvimTreeOpen lua require'nvim-tree'.open()
command! NvimTreeClose lua require'nvim-tree'.close()
command! NvimTreeToggle lua require'nvim-tree'.toggle()
command! NvimTreeRefresh lua require'nvim-tree'.refresh()
command! NvimTreeClipboard lua require'nvim-tree'.print_clipboard()
command! NvimTreeFindFile lua require'nvim-tree'.find_file(true)

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_tree = 1
