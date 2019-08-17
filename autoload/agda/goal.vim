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

let s:pat_pre = '\(^\|\s\|[.(){};]\)\@<='
let s:pat_post = '\($\|\s\|[.(){};]\)\@='

function agda#goal#go_next()
  let l:goals = agda#goal#get_all(bufnr('%'))
  let l:pos = getcurpos()[1:2]
  for [l:type, l:start, l:end] in l:goals
    if s:pos_lt(l:pos, l:start)
      call cursor(l:start[0], l:start[1])
      break
    endif
  endfor
endfunction

function agda#goal#go_prev()
  let l:goals = agda#goal#get_all(bufnr('%'))
  call reverse(l:goals)
  let l:pos = getcurpos()[1:2]
  for [l:type, l:start, l:end] in l:goals
    if s:pos_lt(l:end, l:pos)
      call cursor(l:start[0], l:start[1])
      break
    endif
  endfor
endfunction

function agda#goal#find_current(goals)
  let l:pos = getcurpos()[1:2]
  let l:index = 0
  for [l:type, l:start, l:end] in a:goals
    if s:pos_le(l:start, l:pos) && s:pos_le(l:pos, l:end)
      return l:index
    endif
    let l:index += 1
  endfor
  return -1
endfunction

function s:pos_lt(p, q)
  return a:p[0] < a:q[0] || (a:p[0] == a:q[0] && a:p[1] < a:q[1])
endfunction

function s:pos_le(p, q)
  return s:pos_lt(a:p, a:q) || a:p == a:q
endfunction

function agda#goal#get_body(goal)
  let [l:type, l:start, l:end] = a:goal
  if l:type ==# '?'
    return ''
  else
    let l:lines = getline(l:start[0], l:end[0])
    let l:lines[-1] = l:lines[-1][:l:end[1] - 3]
    let l:lines[0] = l:lines[0][l:start[1] + 1:]
    return join(l:lines, "\n")
  endif
endfunction

function agda#goal#set_body(buf, goal, body)
  let [l:type, l:start, l:end] = a:goal
  let l:body = s:replace_question_mark(a:body)
  let l:lines = split(l:body, "\n")
  let l:prefix = getbufline(a:buf, l:start[0])[0][:l:start[1] - 2]
  let l:suffix = getbufline(a:buf, l:end[0])[0][l:end[1]:]
  let l:lines[0] = l:prefix . l:lines[0]
  let l:lines[-1] = l:lines[-1] . l:suffix
  call s:replace_lines(a:buf, l:start[0], l:end[0], l:lines)
endfunction

function agda#goal#make_case(buf, goal, clauses)
  let [l:type, l:start, l:end] = a:goal
  let l:indent = matchstr(getbufline(a:buf, l:start[0])[0], '^[ \t]*')
  call map(a:clauses, {i, clause ->
    \ l:indent . s:replace_question_mark(clause)})
  call s:replace_lines(a:buf, l:start[0], l:end[0], a:clauses)
endfunction

function s:replace_question_mark(text)
  return substitute(a:text, s:pat_pre . '?' . s:pat_post, '{! !}', 'g')
endfunction

function s:replace_lines(buf, start, end, lines)
  let l:view = winsaveview()
  call deletebufline(a:buf, a:start, a:end)
  call appendbufline(a:buf, a:start - 1, a:lines)
  call winrestview(l:view)
endfunction

function agda#goal#get_all(buf)
  let l:pat_token = join([
    \ s:pat_pre . '--',
    \ '{-', '{!', '!}',
    \ s:pat_pre . '?' . s:pat_post,
  \ ], '\|')

  let l:lines = getbufline(a:buf, 1, '$')

  let l:in_comment = v:false
  let l:goals = []
  let l:stack = []
  let l:lnum = 0

  for l:line in l:lines
    let l:lnum += 1
    let l:len = strlen(l:line)
    let l:off = 0

    while l:off < l:len
      let l:pat = l:in_comment ? '-}' : l:pat_token
      let [l:match, l:start, l:end] = matchstrpos(l:line, l:pat, l:off)

      if l:start == -1
        break
      endif

      if l:match == '--'
        let l:off = l:len
      elseif l:match == '{-'
        let l:in_comment = v:true
        let l:off = l:end
      elseif l:match == '-}'
        let l:in_comment = v:false
        let l:off = l:end
      elseif l:match == '{!'
        call add(l:stack, [l:lnum, l:start + 1])
        let l:off = l:end
      elseif l:match == '!}'
        if !empty(l:stack)
          let l:goal_start = remove(l:stack, -1)
          let l:goal_end = [l:lnum, l:end]
          if empty(l:stack)
            call add(l:goals, ['{!!}', l:goal_start, l:goal_end])
          endif
        endif
        let l:off = l:end
      elseif l:match == '?'
        if empty(l:stack)
          let l:goal_pos = [l:lnum, l:start + 1]
          call add(l:goals, ['?', l:goal_pos, l:goal_pos])
        endif
        let l:off = l:end
      endif
    endwhile
  endfor

  return l:goals
endfunction
