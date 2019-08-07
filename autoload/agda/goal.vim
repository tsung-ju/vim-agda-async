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
  let l:body = substitute(a:body, s:pat_pre . '?' . s:pat_post, '{! !}', 'g')
  let l:lines = split(l:body, "\n")
  let l:prefix = getline(l:start[0])[:l:start[1] - 2]
  let l:suffix = getline(l:end[0])[l:end[1]:]
  let l:lines[0] = l:prefix . l:lines[0]
  let l:lines[-1] = l:lines[-1] . l:suffix
  let l:view = winsaveview()
  call deletebufline(a:buf, l:start[0], l:end[0])
  call appendbufline(a:buf, l:start[0] - 1, l:lines)
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
