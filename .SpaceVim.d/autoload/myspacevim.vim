" see https://spacevim.org/documentation/#bootstrap-functions
function! myspacevim#before() abort
  let bg = 'dark'
  let cur_hour = strftime('%H')

  if cur_hour >= 8 && cur_hour < 18
    let bg = 'light'
  endif

  let g:spacevim_colorscheme_bg = bg
endfunction
