let get_password name =
  if Shadow.shadow_enabled ()
  then Shadow.(with_lock (fun () ->
    (getspnam name).pwd))
  else Passwd.((getpwnam name).passwd)

let put_password name cipher =
  if Shadow.shadow_enabled ()
  then Shadow.(with_lock (fun () ->
    let sp = getspnam name in
    if cipher <> sp.pwd
    then begin
      get_db ()
      |> fun db -> update_db db { sp with pwd = cipher }
      |> write_db
    end))
  else Passwd.(
    let pw = getpwnam name in
    if cipher <> pw.passwd
    then begin
      get_db ()
      |> fun db -> update_db db { pw with passwd = cipher }
      |> write_db
    end)

let rec unshadow acc = function
  | [] -> List.rev acc
  | pw::rest ->
     match Shadow.getspnam pw.Passwd.name with
     | None ->
        unshadow (pw::acc) rest
     | Some sp ->
        unshadow ({ pw with Passwd.passwd = sp.Shadow.passwd }::acc) rest

let unshadow () =
  if not (Shadow.shadow_enabled ())
  then
    Passwd.(get_db () |> db_to_string)
  else
    Shadow.with_lock (fun () -> Passwd.get_db () |> unshadow [])
    |> Passwd.db_to_string

(* Local Variables: *)
(* indent-tabs-mode: nil *)
(* End: *)
