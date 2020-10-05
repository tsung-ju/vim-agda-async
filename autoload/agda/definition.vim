" Copyright (C) 2020  ray851107
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

call prop_type_add('agda_definition', {})

function s:init(buf)
  if getbufvar(a:buf, 'agda_definition_inited', v:false)
    return
  endif

  call setbufvar(a:buf, 'agda_definition_locations', [])
  call setbufvar(a:buf, 'agda_definition_inited', v:true)
endfunction

function agda#definition#go(buf)
  let [l:lnum, l:col] = getcurpos()[1:2]
  let l:prop = prop_find({ 'type': 'agda_definition', 'lnum': l:lnum, 'col': l:col })
  if empty(l:prop) || l:prop.lnum > l:lnum || l:prop.col > l:col
    return
  end

  let l:locations = getbufvar(a:buf, 'agda_definition_locations')
  call s:jump_to(l:locations[l:prop.id])
endfunction

function agda#definition#add(buf, start, end, location)
  call s:init(a:buf)

  let l:locations = getbufvar(a:buf, 'agda_definition_locations')
  call add(l:locations, a:location)
  let l:id = len(l:locations) - 1
  call prop_add(a:start[0], a:start[1], {
    \ 'type': 'agda_definition',
    \ 'end_lnum': a:end[0],
    \ 'end_col': a:end[1],
    \ 'bufnr': a:buf,
    \ 'id': l:id
  \ })
endfunction

function agda#definition#clear(buf)
  if !getbufvar(a:buf, 'agda_definition_inited', v:false)
    return
  endif

  call prop_remove({'type': 'agda_definition', 'bufnr': a:buf, 'all': v:true})
  call setbufvar(a:buf, 'agda_definition_locations', [])
endfunction

function s:jump_to(location)
  let l:newbuf = bufadd(a:location.filepath)
  normal m'
  execute l:newbuf . 'buffer'
  call search('\%^\_.\{' . (a:location.position - 1) . '}\zs', 'w')
endfunction
