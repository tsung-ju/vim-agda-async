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
  let l:goals = agda#goal#get_all(bufnr('%'))
  let l:goal_index = agda#goal#find_current(l:goals)

  if l:goal_index == -1
    echoerr 'For this command, please place the cursor in a goal'
    return
  endif

  let l:goal_name = b:agda_ctx.interaction_points[l:goal_index]

  let l:goal_body = agda#goal#get_body(goals[l:goal_index])

  let l:cmd = a:cmd + [
    \ l:goal_name,
    \ 'noRange',
    \ json_encode(l:goal_body) ]
  call s:send_command('(' . join(l:cmd) . ')')
endfunction

function s:start_agda()
  if !exists('b:agda_ctx')
    let l:ctx = {}
    let l:ctx.buf = bufnr('%')
    let l:ctx.interaction_points = []
    let l:ctx.job = job_start(
      \ ['agda', '--interaction-json'],
      \ {'out_cb': function('s:handle_response', [l:ctx])})
    let l:ctx.ch = job_getchannel(l:ctx.job)
    let b:agda_ctx = l:ctx
  endif
endfunction

function s:stop_agda()
  if exists('b:agda_ctx')
    call jobstop(b:agda_ctx.job)
    unlet b:agda_ctx
  endif
endfunction

function s:send_command(interatcion)
  let l:args = [
    \ 'IOTCM',
    \ json_encode(expand('%')),
    \ 'NonInteractive',
    \ 'Direct',
    \ a:interatcion ]

  call s:start_agda()

  call ch_sendraw(b:agda_ctx.ch, join(l:args) . "\n")
endfunction

function s:handle_response(ctx, ch, msg)
  let l:msg = s:parse_response(a:msg)
  echom l:msg.kind
  if l:msg.kind !=# 'HighlightingInfo'
    echom string(l:msg)
  endif
  if has_key(s:handler, l:msg.kind)
    call s:handler[l:msg.kind](a:ctx, l:msg)
  endif
endfunction

function s:parse_response(msg)
  return json_decode(substitute(a:msg, '^JSON> ', '', ''))
endfunction

let s:handler = {}
function s:handler.RunningInfo(ctx, msg)
  for l:line in split(a:msg.message, "\n")
    echom l:line
  endfor
endfunction

function s:handler.ClearHighlighting(ctx, msg)
  call agda#highlight#clear(a:ctx.buf)
endfunction

function s:handler.InteractionPoints(ctx, msg)
  let a:ctx.interaction_points = a:msg.interactionPoints
endfunction

function s:handler.HighlightingInfo(ctx, msg)
  call agda#highlight#highlight(a:ctx.buf, a:msg.info.payload)
endfunction

function s:handler.GiveAction(ctx, msg)
  let l:goal_index = index(a:ctx.interaction_points, a:msg.interactionPoint)
  if l:goal_index != -1
    let l:goal = agda#goal#get_all(a:ctx.buf)[l:goal_index]
    call agda#goal#set_body(a:ctx.buf, l:goal, a:msg.giveResult)
  endif
endfunction
