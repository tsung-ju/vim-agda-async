let s:question_mark_pattern = '\(^\|(\|)\|{\|}\| \)\@<=?\($\|(\|)\|{\|}\| \)\@='

function agda#goal#go_next()
  let l:goals = s:find_goals()
  let l:pos = getcurpos()[1:2]
  for l:goal in l:goals
    if s:pos_lt(l:pos, l:goal.start)
      call cursor(l:goal.start[0], l:goal.start[1])
      break
    endif
  endfor
endfunction

function agda#goal#go_prev()
  let l:goals = s:find_goals()
  call reverse(l:goals)
  let l:pos = getcurpos()[1:2]
  for l:goal in l:goals
    if s:pos_lt(l:goal.end, l:pos)
      call cursor(l:goal.start[0], l:goal.start[1])
      break
    endif
  endfor
endfunction

function agda#goal#find_current(goals)
  let l:pos = getcurpos()[1:2]
  let l:index = 0
  for l:goal in a:goals
    if s:pos_le(l:goal.start, l:pos) && s:pos_le(l:pos, l:goal.end)
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
  if a:goal.type ==# '?'
    return ''
  else
    let l:lines = getline(a:goal.start[0], a:goal.end[0])
    let l:lines[-1] = l:lines[-1][:a:goal.end[1] - 3]
    let l:lines[0] = l:lines[0][a:goal.start[1] + 1:]
    return join(l:lines, "\n")
  endif
endfunction

function agda#goal#set_body(buf, goal, body)
  let l:body = substitute(a:body, s:question_mark_pattern, '{! !}', 'g')
  let l:lines = split(l:body, "\n")
  let l:prefix = getline(a:goal.start[0])[:a:goal.start[1] - 2]
  let l:suffix = getline(a:goal.end[0])[a:goal.end[1]:]
  let l:lines[0] = l:prefix . l:lines[0]
  let l:lines[-1] = l:lines[-1] . l:suffix
  let l:view = winsaveview()
  call deletebufline(a:buf, a:goal.start[0], a:goal.end[0])
  call appendbufline(a:buf, a:goal.start[0] - 1, l:lines)
  call winrestview(l:view)
endfunction

function agda#goal#get_all()
  let l:view = winsaveview()
  call cursor(1, 1)

  let l:goals = []
  let l:stack = []
  while 1
    let l:match = search('\(--\)\|\({-\)\|\({!\)\|\(!}\)\|\(' . s:question_mark_pattern . '\)', 'ceWzp')
    if l:match == 0
      break
    elseif l:match == 2
      " --
      call search('$', 'cWz')
    elseif l:match == 3
      " {-
      if search('-}', 'eWz') == 0
        break
      endif
    elseif l:match == 4
      " {!
      let [l:lnum, l:col] = getcurpos()[1:2]
      call add(l:stack, [l:lnum, l:col - 1])
    elseif l:match == 5
      " !}
      if !empty(l:stack)
        let l:start = remove(l:stack, -1)
        let l:end = getcurpos()[1:2]
        if empty(l:stack)
          call add(l:goals, {'type': '{!!}', 'start': l:start, 'end': l:end})
        endif
      endif
    elseif l:match == 7
      " ?
      let l:pos = getcurpos()[1:2]
      if empty(l:stack)
        call add(l:goals, {'type': '?', 'start': l:pos, 'end': l:pos}) 
      endif
    endif
    if search('.', 'Wz') == 0
      break
    endif
  endwhile

  call winrestview(l:view)
  return l:goals
endfunction
