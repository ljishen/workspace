" see https://spacevim.org/documentation/#bootstrap-functions
function! myspacevim#before() abort
  let bg = 'light'

  " 18 is 6PM
  if strftime('%H') >= 18
    let bg = 'dark'
  endif

  let g:spacevim_colorscheme_bg = bg
endfunction
