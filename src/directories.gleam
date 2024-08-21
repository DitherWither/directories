import gleam/erlang/os
import gleam/io
import gleam/list
import gleam/result
import simplifile

/// Return the first environment variable from the list
/// that is set and is a valid directory
fn check_dir_from_env(vars: List(String)) -> Result(String, Nil) {
  vars |> list.filter_map(os.get_env(_)) |> check_dirs
}

/// Return the first directory from the list that exists, or Nil
fn check_dirs(paths: List(String)) -> Result(String, Nil) {
  paths
  |> list.filter(fn(a) { result.unwrap(simplifile.is_directory(a), False) })
  |> list.first
}

pub fn tmp_directory() {
  // This behavior is mostly copied from how python's tempfile module works with small changes
  // It'll first check the set of env vars, then the known paths, and if none of them exist, the current working directory
  // TODO: check if this even works on windows
  case check_dir_from_env(["TMPDIR", "TEMP", "TMP"]) {
    Ok(path) -> path
    Error(Nil) -> {
      case os.family() {
        os.WindowsNt ->
          result.unwrap(
            check_dirs(["C:\\TEMP", "C:\\TMP", "\\TEMP", "\\TMP"]),
            ".",
          )
        _ -> result.unwrap(check_dirs(["/tmp", "/var/tmp", "/usr/tmp"]), ".")
      }
    }
  }
}

pub fn main() {
  tmp_directory() |> io.debug
}
