function agda#input#activate()
  augroup agda_input
    autocmd! * <buffer>
    autocmd TextChangedI <buffer> call s:update()
    autocmd TextChangedP <buffer> call s:update()
    autocmd CursorMovedI <buffer> call s:update()
    autocmd InsertLeave <buffer> call s:commit()
  augroup END

  inoremap <buffer><silent> \ <C-\><C-O>:call <SID>start()<CR>\

  hi def agda_input_pending term=underline cterm=underline gui=underline
  hi def link agda_input_matched Underlined
endfunction

function agda#input#map(source, targets)
  call s:trie_add('\' . source, targets)
endfunction

let s:state = {'started': v:false}

function s:start()
  call s:commit()

  let [l:lnum, l:col] = getcurpos()[1:2]
  let l:popup = popup_create('', {
    \ 'line': l:lnum + 1,
    \ 'col': l:col,
    \ 'wrap': v:false,
    \ 'hidden': v:true,
    \ 'cursorline': 1,
    \ 'minwidth': 5,
    \ 'maxheight': 5,
    \ 'filter': function('s:popup_filter'),
    \ 'callback': function('s:popup_callback'),
  \ })

  let s:state = {
    \ 'started': v:true,
    \ 'lnum': l:lnum,
    \ 'start': l:col,
    \ 'match_ids': [],
    \ 'popup': l:popup,
  \ }
endfunction

function s:update()
  if !s:state.started
    return
  endif

  let [l:lnum, l:col] = getcurpos()[1:2]

  if l:lnum != s:state.lnum
    return s:commit()
  endif

  if l:col <= s:state.start
    return s:reset()
  endif

  let l:text = s:getline_range(l:lnum, s:state.start, l:col - s:state.start)
  let s:state.match = s:trie_match(l:text)

  call s:update_highlight(s:state, l:col)
  call s:update_popup(s:state)

  if empty(s:state.match.children)
    return s:commit()
  endif
endfunction


function s:commit(index=0)
  if !s:state.started
    return
  endif

  if !has_key(s:state, 'match') || empty(s:state.match.prefix)
    return s:reset()
  endif

  " save cursor position
  let [l:lnum, l:col] = getcurpos()[1:2]

  let l:prefix_len = strlen(s:state.match.prefix)
  let l:replacement = s:state.match.replacements[a:index]

  call s:setline_range(
    \ s:state.lnum,
    \ s:state.start,
    \ l:prefix_len,
    \ l:replacement)

  " restore cursor position
  if l:lnum == s:state.lnum && l:col >= s:state.start
    if l:col < s:state.start + l:prefix_len
      let l:col = s:state.start + l:prefix_len
    endif
    let l:col += strlen(l:replacement) - l:prefix_len
    call cursor(l:lnum, l:col)
  endif

  call s:reset()
endfunction

function s:reset()
  if !s:state.started
    return
  endif
  call s:clear_highlight(s:state)
  call popup_close(s:state.popup, -1)
  let s:state = {'started': v:false}
endfunction

function s:getline_range(lnum, start, len)
  let l:line = getline(a:lnum)
  return strpart(l:line, a:start - 1, a:len)
endfunction

function s:setline_range(lnum, start, len, text)
  let l:line = getline(a:lnum)
  let l:pre = strpart(l:line, 0, a:start - 1)
  let l:post = strpart(l:line, a:start - 1 + a:len)
  call setline(a:lnum, l:pre . a:text . l:post)
endfunction

function s:update_highlight(state, col)
  call s:clear_highlight(a:state)

  let l:ids = a:state.match_ids
  let l:start = a:state.start
  let l:lnum = a:state.lnum

  call add(l:ids, matchaddpos(
    \ 'agda_input_pending',
    \ [[l:lnum, l:start, a:col - l:start]]))

  if has_key(a:state, 'match')
    let l:prefix = a:state.match.prefix
    if !empty(l:prefix)
      call add(l:ids, matchaddpos(
        \ 'agda_input_matched', 
        \ [[l:lnum, l:start, strlen(l:prefix)]]))
    endif
  endif
endfunction

function s:clear_highlight(state)
  for l:match_id in a:state.match_ids
    call matchdelete(l:match_id)
  endfor
  let a:state['match_ids'] = []
endfunction

function s:update_popup(state)
  let l:popup = a:state.popup
  let l:replacements = a:state.match.replacements

  if empty(l:replacements)
    call popup_hide(l:popup)
  else
    call popup_show(l:popup)
    call popup_settext(l:popup, l:replacements)
    call win_execute(l:popup, 'call cursor(1, 1)')
  endif
endfunction

function s:popup_filter(popup, key)
  if index(["\<Up>", "\<Down>", "\<Enter>"], a:key) != -1
    return popup_filter_menu(a:popup, a:key)
  else
    return 0
  endif
endfunction

function s:popup_callback(popup, result)
  if a:result != -1
    call s:commit(a:result - 1)
  endif
endfunction

function s:trie_add(key, values)
  let l:node = agda#input#trie#get()
  for l:i in range(strchars(a:key))
    let l:char = strcharpart(a:key, l:i, 1)
    if !has_key(l:node[0], l:char)
      let l:dict = l:node[0]
      let l:dict[l:char] = [{}, []]
    endif
    let l:node = l:node[0][l:char]
  endfor
  call extend(l:node[1], a:values)
endfunction

function s:trie_match(key)
  let l:node = agda#input#trie#get()
  let l:prefix = ''
  let l:replacements = l:node[1]
  for l:i in range(strchars(a:key))
    let l:char = strcharpart(a:key, l:i, 1)
    if !has_key(l:node[0], l:char)
      return {
        \ 'prefix': l:prefix,
        \ 'replacements': l:replacements,
        \ 'children': [] }
    endif
    let l:node = l:node[0][l:char]
    if !empty(l:node[1])
      let l:prefix = strcharpart(a:key, 0, l:i + 1)
      let l:replacements = l:node[1]
    endif
  endfor
  return {
    \ 'prefix': l:prefix,
    \ 'replacements': l:replacements,
    \ 'children': keys(l:node[0]) }
endfunction
