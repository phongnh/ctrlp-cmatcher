" CtrlP C matching extension
"
" By: Stanislav Golovanov <stgolovanov@gmail.com>
"     MaxSt <https://github.com/MaxSt>
"     Aaron Jensen <aaronjensen@gmail.com>
"
" See LICENSE for licensing concerns.

if !has('python3')
    echom 'ctrlp-cmatcher requires python3!'
    finish
endif

let s:script_folder_path = escape( expand( '<sfile>:p:h' ), '\' )
unsilent execute 'py3file ' . s:script_folder_path . '/matcher.py'

fu! s:matchtabs(item, pat)
  return match(split(a:item, '\t\+')[0], a:pat)
endf

fu! s:matchfname(item, pat)
  let parts = split(a:item, '[\/]\ze[^\/]\+$')
  return match(parts[-1], a:pat)
endf

fu! s:escapechars(chars)
  if exists('+ssl') && !&ssl
    cal map(a:chars, 'escape(v:val, ''\'')')
  en
  for each in ['^', '$', '.']
    cal map(a:chars, 'escape(v:val, each)')
  endfo

  return a:chars
endfu

fu! s:highlight(input, mmode, regex)
    " highlight matches
    cal clearmatches()
    if a:regex
      let pat = ""
      if a:mmode == "filename-only"
        let pat = substitute(a:input, '\$\@<!$', '\\ze[^\\/]*$', 'g')
      en
      if empty(pat)
        let pat = substitute(a:input, '\\\@<!\^', '^> \\zs', 'g')
      en
      cal matchadd('CtrlPMatch', '\c'.pat)
    el
      let chars = split(a:input, '\zs')
      let chars = s:escapechars(chars)

      " Build a pattern like /a.*b.*c/ from abc (but with .\{-} non-greedy
      " matchers instead)
      let pat = join(chars, '.\{-}')
      " Ensure we match the last version of our pattern
      let ending = '\(.*'.pat.'\)\@!'
      " Case insensitive
      let beginning = '\c^.*'
      if a:mmode == "filename-only"
        " Make sure there are no slashes in our match
        let beginning = beginning.'\([^\/]*$\)\@='
      end

      for i in range(len(a:input))
        " Surround our current target letter with \zs and \ze so it only
        " actually matches that one letter, but has all preceding and trailing
        " letters as well.
        " \zsa.*b.*c
        " a\(\zsb\|.*\zsb)\ze.*c
        let charcopy = copy(chars)
        if i == 0
          let charcopy[i] = '\zs'.charcopy[i].'\ze'
          let middle = join(charcopy, '.\{-}')
        else
          let before = join(charcopy[0:i-1], '.\{-}')
          let after = join(charcopy[i+1:-1], '.\{-}')
          let c = charcopy[i]
          " for abc, match either ab.\{-}c or a.*b.\{-}c in that order
          let cpat = '\(\zs'.c.'\|'.'.*\zs'.c.'\)\ze.*'
          let middle = before.cpat.after
        endif

        " Now we matchadd for each letter, the basic form being:
        " ^.*\zsx\ze.*$, but with our pattern we built above for the letter,
        " and a negative lookahead ensuring that we only highlight the last
        " occurrence of our letters. We also ensure that our matcher is case
        " insensitive.
        cal matchadd('CtrlPMatch', beginning.middle.ending)
      endfor
    en
    cal matchadd('CtrlPLinePre', '^>')
endf

fu! matcher#cmatch(lines, input, limit, mmode, ispath, crfile, regex)
  if a:input == ''
    " Clear matches, that left from previous matches
    cal clearmatches()
    " Hack to clear s:savestr flag in SplitPattern, otherwise matching in
    " 'tag' mode will work only from 2nd char.
    cal ctrlp#call('s:SplitPattern', '')
    let array = a:lines[0:a:limit]
    if a:ispath && !empty(a:crfile)
      cal remove(array, index(array, a:crfile))
    en
    return array
  el
    if a:regex
      let array = []
      let func = a:mmode == "filename-only" ? 's:matchfname' : 'match'
      for item in a:lines
        if call(func, [item, a:input]) >= 0
          cal add(array, item)
        endif
      endfor
      cal sort(array, ctrlp#call('s:mixedsort'))
      cal s:highlight(a:input, a:mmode, a:regex)
      return array
    endif
    " use built-in matcher if mmode set to match until first tab ( in other case
    " tag.vim doesnt work
    if a:mmode == "first-non-tab"
      let array = []
      " call ctrlp.vim function to get proper input pattern
      let pat = ctrlp#call('s:SplitPattern', a:input)
      for item in a:lines
        if call('s:matchtabs', [item, pat]) >= 0
          cal add(array, item)
        en
      endfo
      "TODO add highlight
      cal sort(array, ctrlp#call('s:mixedsort'))
      return array
    en

    let matchlist = py3eval("ctrlp_cmatcher_match()")
  en

  cal s:highlight(a:input, a:mmode, a:regex)

  return matchlist
endf
