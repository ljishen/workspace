" see https://spacevim.org/documentation/#bootstrap-functions
function! myspacevim#before() abort
  let cur_hour = strftime('%H')

  let g:spacevim_colorscheme_bg = 'dark'
  if cur_hour >= 8 && cur_hour < 18
    let g:spacevim_colorscheme_bg = 'light'
  endif

  " Fix 'cscope: command not found' in the installation process
  " https://github.com/SpaceVim/SpaceVim/blob/7ab985d96a79131723d8942027719b89c940ebef/bundle/cscope.vim/autoload/cscope.vim#L56
  let g:cscope_cmd = executable('cscope') ? 'cscope' : '/usr/bin/cscope'
endfunction
