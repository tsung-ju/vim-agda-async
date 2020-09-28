" Copyright (C) 2019  ray851107
"
" This file is part of vim-agda-async.
"
" vim-agda-async is free software: you can redistribute it and/or modify
" it under the terms of the GNU General Public License as published by
" the Free Software Foundation, either version 3 of the License, or
" (at your option) any later version.
"
" vim-agda-async is distributed in the hope that it will be useful,
" but WITHOUT ANY WARRANTY; without even the implied warranty of
" MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
" GNU General Public License for more details.
"
" You should have received a copy of the GNU General Public License
" along with vim-agda-async.  If not, see <https://www.gnu.org/licenses/>.

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

let s:state = {'started': v:false}

function s:start()
  call s:commit()

  let l:popup = popup_create('', {
    \ 'line': 'cursor+1',
    \ 'col': 'cursor',
    \ 'wrap': v:false,
    \ 'hidden': v:true,
    \ 'cursorline': 1,
    \ 'minwidth': 5,
    \ 'maxheight': 5,
    \ 'filter': function('s:popup_filter'),
  \ })

  let l:start_pos = getcurpos()[1:2]
  let s:state = {
    \ 'started': v:true,
    \ 'start_pos': l:start_pos,
    \ 'match': '',
    \ 'choice': 0,
    \ 'candidates': [],
    \ 'highlights': [],
    \ 'popup': l:popup,
  \ }
endfunction

function s:update()
  if !s:state.started
    return
  endif

  let [l:start_lnum, l:start_col] = s:state.start_pos
  let [l:end_lnum, l:end_col] = getcurpos()[1:2]

  if l:end_lnum != l:start_lnum 
    return s:commit()
  endif

  if l:end_col <= l:start_col
    return s:reset()
  endif

  let l:text = s:getline_range(l:start_lnum, l:start_col, l:end_col - l:start_col)
  let [l:match, l:candidates, l:children] = s:trie_match(l:text)

  if l:match !=# s:state.match
    let s:state.match = l:match
    let s:state.candidates = l:candidates
    let s:state.choice = 0
  endif

  call s:update_highlight(s:state, l:end_col)
  call s:update_popup(s:state)

  if l:match !=# l:text && empty(l:children)
    return s:commit()
  endif
endfunction


function s:commit()
  if !s:state.started
    return
  endif

  if empty(s:state.candidates)
    return s:reset()
  endif

  let [l:start_lnum, l:start_col] = s:state.start_pos
  " save cursor position
  let [l:end_lnum, l:end_col] = getcurpos()[1:2]

  let l:match_len = strlen(s:state.match)
  let l:replacement = s:state.candidates[s:state.choice]

  call s:setline_range(
    \ l:start_lnum,
    \ l:start_col,
    \ l:match_len,
    \ l:replacement)

  " restore cursor position
  if l:start_lnum == l:end_lnum && l:start_col <= l:end_col
    call cursor(l:end_lnum, l:end_col - l:match_len + strlen(l:replacement))
  endif

  call s:reset()
endfunction

function s:reset()
  if !s:state.started
    return
  endif
  call s:clear_highlight(s:state)
  call popup_close(s:state.popup)
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

function s:update_highlight(state, end_col)
  call s:clear_highlight(a:state)

  let l:highlights = a:state.highlights
  let [l:start_lnum, l:start_col] = s:state.start_pos
  let l:match = a:state.match

  call add(l:highlights, matchaddpos(
    \ 'agda_input_pending',
    \ [[l:start_lnum, l:start_col, a:end_col - l:start_col]]))

  if !empty(l:match)
    call add(l:highlights, matchaddpos(
      \ 'agda_input_matched', 
      \ [[l:start_lnum, l:start_col, strlen(l:match)]]))
  endif
endfunction

function s:clear_highlight(state)
  for l:highlight in a:state.highlights
    call matchdelete(l:highlight)
  endfor
  let a:state.highlights = []
endfunction

function s:update_popup(state)
  let l:popup = a:state.popup
  let l:candidates = a:state.candidates
  let l:choice = a:state.choice

  if empty(l:candidates)
    call popup_hide(l:popup)
  else
    call popup_show(l:popup)
    call popup_settext(l:popup, l:candidates)
    call s:popup_set_choice(l:popup, a:state.choice)
  endif
endfunction

function s:popup_filter(popup, key)
  if index(["\<Up>", "\<S-Tab>"], a:key) != -1
    let s:state.choice =
      \ s:mod(s:state.choice - 1, len(s:state.candidates))
    call s:popup_set_choice(a:popup, s:state.choice)
    return 1
  endif

  if index(["\<Down>", "\<Tab>"], a:key) != -1
    let s:state.choice =
      \ s:mod(s:state.choice + 1, len(s:state.candidates))
    call s:popup_set_choice(a:popup, s:state.choice)
    return 1
  endif

  if a:key ==# "\<Enter>"
    call s:commit()
    return 1
  endif

  return 0
endfunction

function s:popup_set_choice(popup, choice)
  let l:command = printf('call cursor(%d, 1)', a:choice + 1)
  call win_execute(a:popup, l:command)
  call popup_setoptions(a:popup, {'cursorline': 1})
endfunction

function s:mod(n, m)
  return ((a:n % a:m) + a:m) % a:m
endfunction

function s:trie_match(key)
  let l:node = agda#input#trie#get()
  let l:match = ''
  let l:candidates = l:node[1]
  for l:i in range(strchars(a:key))
    let l:char = strcharpart(a:key, l:i, 1)
    if !has_key(l:node[0], l:char)
      return [l:match, l:candidates, []]
    endif
    let l:node = l:node[0][l:char]
    if !empty(l:node[1])
      let l:match = strcharpart(a:key, 0, l:i + 1)
      let l:candidates = l:node[1]
    endif
  endfor
  return [l:match, l:candidates, keys(l:node[0])]
endfunction
