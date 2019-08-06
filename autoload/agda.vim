function agda#reset_syntax()
  syntax clear
  runtime syntax/agda.vim
endfunction

function agda#reload_syntax()
  call agda#reset_syntax()
  let l:path = expand('%:h') . '/.' . expand('%:t') . '.vim'
  if filereadable(l:path)
    exec 'source ' . escape(l:path, '*')
  endif
endfunction

function agda#load()
  call s:send_command('(Cmd_load ' . json_encode(expand('%')) . ' [])')
endfunction

function agda#compile()
  call s:send_command('(Cmd_compile MAlonzo ' . json_encode(expand('%')) . ' [])')
endfunction

function agda#constraints()
  call s:send_command('(Cmd_constraints)')
endfunction

function agda#metas()
  call s:send_command('(Cmd_metas)')
endfunction

function agda#give(use_force)
  call s:goal_command(['Cmd_give', a:use_force])
endfunction

function agda#refine()
  call s:goal_command(['Cmd_refine_or_intro', 'False'])
endfunction

function s:goal_command(cmd)
  let l:goals = s:find_goals()
  let l:goal_index = s:current_goal_index(l:goals)
  if l:goal_index == -1
    echoerr 'For this command, please place the cursor in a goal'
    return
  endif

  let l:ch = job_getchannel(b:agda_job)
  let l:interaction_points = s:get_channel_data(l:ch).interaction_points
  let l:goal_name = l:interaction_points[l:goal_index]

  let l:goal_body = s:get_goal_body(goals[l:goal_index])

  let l:cmd = a:cmd + [
    \ l:goal_name,
    \ 'noRange',
    \ json_encode(l:goal_body) ]
  call s:send_command('(' . join(l:cmd) . ')')
endfunction

let s:channel_data = {}
function s:get_channel_data(ch)
  let l:id = ch_info(a:ch).id
  return s:channel_data[l:id]
endfunction

function s:set_channel_data(ch, data)
  let l:id = ch_info(a:ch).id
  let s:channel_data[l:id] = a:data
endfunction

function s:remove_channel_data(ch)
  let l:id = ch_info(a:ch).id
  call remove(s:channel_data, l:id)
endfunction


function s:start_agda()
  if !exists('b:agda_job')
    let l:job = job_start(
      \ ['agda', '--vim', '--interaction-json'],
      \ {'out_cb': function('s:handle_response')})
    let l:channel = job_getchannel(l:job)
    let b:agda_job = l:job
    call s:set_channel_data(l:channel, {
      \ 'buf': bufnr('%'),
      \ 'interaction_points': []
    \ })
  endif
endfunction

function s:stop_agda()
  if exists('b:agda_job')
    call s:remove_channel_data(job_getchannel(b:agda_job))
    call jobstop(b:agda_job)
    unlet b:agda_job
  endif
endfunction

function s:send_command(interatcion)
  let l:args = [
    \ 'IOTCM',
    \ json_encode(expand('%')),
    \ 'NonInteractive',
    \ 'Direct',
    \ a:interatcion ]

  if !exists('b:agda_job')
    call s:start_agda()
  endif

  let l:channel = job_getchannel(b:agda_job)

  call ch_sendraw(l:channel, join(l:args) . "\n")
endfunction

function s:handle_response(ch, msg)
  let l:msg = s:parse_response(a:msg)
  if l:msg.kind !=# 'HighlightingInfo'
    echom l:msg.kind
    echom string(l:msg)
  endif
  if has_key(s:handler, l:msg.kind)
    call s:handler[l:msg.kind](a:ch, l:msg)
  endif
endfunction

function s:parse_response(msg)
  return json_decode(substitute(a:msg, '^JSON> ', '', ''))
endfunction

let s:handler = {}
function s:handler.Status(ch, msg)
  let l:buf = s:get_channel_data(a:ch).buf
  if l:buf == bufnr('%')
    call agda#reload_syntax()
  endif
endfunction

function s:handler.RunningInfo(ch, msg)
  for l:line in split(a:msg.message, "\n")
    echom l:line
  endfor
endfunction

function s:handler.ClearHighlighting(ch, msg)
  let l:buf = s:get_channel_data(a:ch).buf
  if l:buf == bufnr('%')
    call agda#reset_syntax()
  endif
  cclose
  call setqflist([], 'r')
endfunction

function s:handler.InteractionPoints(ch, msg)
  let l:channel_data = s:get_channel_data(a:ch)
  let l:channel_data.interaction_points = a:msg.interactionPoints
endfunction

let s:error_atoms = [
  \ 'error',
  \ 'unsolvedmeta',
  \ 'unsolvedconstraint',
  \ 'terminationproblem',
  \ 'deadcode',
  \ 'coverageproblem',
  \ 'positivityproblem',
  \ 'incompletepattern',
  \ 'catchallclause',
  \ 'confluenceproblem',
\ ]

function s:handler.HighlightingInfo(ch, msg)
  let l:inited = 0
  let l:buf = s:get_channel_data(a:ch).buf

  for l:item in a:msg.info.payload
    for l:atom in l:item.atoms
      if index(s:error_atoms, l:atom) == -1
        continue
      endif

      if !l:inited
        let l:lines = getbufline(l:buf, 1, '$')
        let l:line_starts = s:line_starts(l:lines)
        let l:inited = 1
      endif

      if has_key(l:item, 'note') && l:item.note != v:null
        let l:text = l:item.note
      else
        let l:text = l:atom
      endif

      let l:start = l:item.range[0]
      let [l:lnum, l:col] = s:chars2pos(l:lines, l:line_starts, l:start)
      call setqflist([{
        \ 'bufnr': l:buf,
        \ 'lnum': l:lnum,
        \ 'col': l:col,
        \ 'text': l:text,
      \ }], 'a')

      break
    endfor
  endfor
endfunction

function s:line_starts(lines)
  let l:line_starts = []
  let l:acc = 1
  for l:line in a:lines
    call add(l:line_starts, l:acc)
    let acc += strchars(l:line) + 1
  endfor
  return l:line_starts
endfunction

function s:chars2pos(lines, line_starts, chars)
  let l:lnum = 0
  for l:line_start in a:line_starts
    if l:line_start > a:chars
      break
    else
      let l:lnum += 1
    endif
  endfor
  let l:charcol = a:chars - a:line_starts[l:lnum - 1] + 1
  let l:col = strlen(strcharpart(a:lines[l:lnum - 1], 0, l:charcol))
  return [l:lnum, l:col]
endfunction

function s:handler.GiveAction(ch, msg)
  let l:channel_data = s:get_channel_data(a:ch)
  let l:buf = l:channel_data.buf
  let l:interaction_points = l:channel_data.interaction_points
  let l:goal_index = index(l:interaction_points, a:msg.interactionPoint)
  let l:goal = s:find_goals()[l:goal_index]
  call s:set_goal_body(l:buf, l:goal, a:msg.giveResult)
endfunction

let s:question_mark_pattern = '\(^\|(\|)\|{\|}\| \)\@<=?\($\|(\|)\|{\|}\| \)\@='

function agda#next_goal()
  let l:goals = s:find_goals()
  let l:pos = getcurpos()[1:2]
  for l:goal in l:goals
    if s:pos_lt(l:pos, l:goal.start)
      call cursor(l:goal.start[0], l:goal.start[1])
      break
    endif
  endfor
endfunction

function agda#prev_goal()
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

function s:current_goal_index(goals)
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
  return a:p[0] <= a:q[0] || (a:p[0] == a:q[0] && a:p[1] <= a:q[1])
endfunction

function s:get_goal_body(goal)
  if a:goal.type ==# '?'
    return ''
  else
    let l:lines = getline(a:goal.start[0], a:goal.end[0])
    let l:lines[-1] = l:lines[-1][:a:goal.end[1] - 3]
    let l:lines[0] = l:lines[0][a:goal.start[1] + 1:]
    return join(l:lines, "\n")
  endif
endfunction

function s:set_goal_body(buf, goal, body)
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

function s:find_goals()
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
