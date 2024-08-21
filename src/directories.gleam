import gleam/erlang/os
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

/// Return the first environment variable from the list
/// that is set and is a valid directory
fn check_dir_from_env(vars: List(String)) -> Result(String, Nil) {
  vars |> list.filter_map(os.get_env(_)) |> check_dirs
}

/// Return the first directory from the list that exists, or Nil
fn check_dirs(paths: List(String)) -> Result(String, Nil) {
  paths
  |> list.filter(fn(a) {
    !string.is_empty(a) && result.unwrap(simplifile.is_directory(a), False)
  })
  |> list.first
}

fn get_env(var: String) -> String {
  result.unwrap(os.get_env(var), "")
}

fn home_dir_path(path: String) -> String {
  get_env("HOME") <> path
}

fn other_os_message(other_os: String) -> Result(String, Nil) {
  io.print_error(
    "[WARN][directories] Operating system '"
    <> other_os
    <> "' is not supported by this library",
  )
  Error(Nil)
}

pub fn tmp_dir() -> Result(String, Nil) {
  // This behavior is mostly copied from how python's tempfile module works with small changes
  // It'll first check the set of env vars, then the known paths, and if none of them exist, the current working directory
  // TODO: check if this even works on windows
  case check_dir_from_env(["TMPDIR", "TEMP", "TMP"]) {
    Ok(path) -> Ok(path)
    Error(Nil) -> {
      case os.family() {
        os.WindowsNt -> check_dirs(["C:\\TEMP", "C:\\TMP", "\\TEMP", "\\TMP"])
        os.Darwin | os.Linux | os.FreeBsd ->
          check_dirs(["/tmp", "/var/tmp", "/usr/tmp"])
        os.Other(os) -> other_os_message(os)
      }
    }
  }
}

pub fn home_dir() -> Result(String, Nil) {
  case os.family() {
    os.WindowsNt -> check_dir_from_env(["UserProfile", "Profile"])
    os.Darwin | os.Linux | os.FreeBsd -> check_dir_from_env(["HOME"])
    os.Other(os) -> other_os_message(os)
  }
}

pub fn cache_dir() -> Result(String, Nil) {
  case os.family() {
    os.WindowsNt -> check_dir_from_env(["APPDATA"])
    os.Darwin -> check_dirs([get_env("HOME") <> "/Library/Caches"])
    os.Linux | os.FreeBsd ->
      check_dirs([get_env("XDG_CACHE_HOME"), home_dir_path("/.cache")])
    os.Other(os) -> other_os_message(os)
  }
}

pub fn config_dir() -> Result(String, Nil) {
  case os.family() {
    os.WindowsNt -> check_dir_from_env(["APPDATA"])
    os.Darwin -> check_dirs([get_env("HOME") <> "/Library/Application Support"])
    os.Linux | os.FreeBsd ->
      check_dirs([get_env("XDG_CONFIG_HOME"), home_dir_path("/.config")])
    os.Other(os) -> other_os_message(os)
  }
}

pub fn config_local_dir() -> Result(String, Nil) {
  case os.family() {
    os.WindowsNt -> check_dir_from_env(["LOCALAPPDATA"])
    _ -> config_dir()
  }
}

pub fn data_dir() -> Result(String, Nil) {
  case os.family() {
    os.Linux | os.FreeBsd ->
      check_dirs([get_env("XDG_DATA_HOME"), home_dir_path("/.local/share")])
    _ -> config_dir()
  }
}

pub fn data_local_dir() -> Result(String, Nil) {
  case os.family() {
    os.WindowsNt -> check_dir_from_env(["APPDATA"])
    _ -> data_dir()
  }
}

pub fn executable_dir() -> Result(String, Nil) {
  case os.family() {
    os.WindowsNt | os.Darwin -> Error(Nil)
    os.Linux | os.FreeBsd ->
      check_dirs([
        get_env("XDG_BIN_HOME"),
        home_dir_path("/.local/bin"),
        get_env("XDG_DATA_HOME") <> "../bin",
      ])
    os.Other(os) -> other_os_message(os)
  }
}

pub fn preference_dir() -> Result(String, Nil) {
  case os.family() {
    os.Darwin -> check_dirs([home_dir_path("/Library/Preferences")])
    _ -> config_dir()
  }
}

pub fn runtime_dir() -> Result(String, Nil) {
  case os.family() {
    os.Linux | os.FreeBsd -> check_dir_from_env(["XDG_RUNTIME_DIR"])
    os.Other(os) -> other_os_message(os)
    _ -> Error(Nil)
  }
}

pub fn state_dir() -> Result(String, Nil) {
  case os.family() {
    os.Linux | os.FreeBsd ->
      check_dirs([get_env("XDG_STATE_HOME"), home_dir_path("/.local/state")])
    os.Other(os) -> other_os_message(os)
    _ -> Error(Nil)
  }
}

pub fn main() {
  io.print("Current Platform: ")
  let _ = io.debug(os.family())
  io.println("===")
  io.print("Temp Directory: ")
  let _ = io.debug(tmp_dir())
  io.print("Home Directory: ")
  let _ = io.debug(home_dir())
  io.print("Cache Directory: ")
  let _ = io.debug(cache_dir())
  io.print("Config Directory: ")
  let _ = io.debug(config_dir())
  io.print("Config Directory (Local): ")
  let _ = io.debug(config_local_dir())
  io.print("Data Directory: ")
  let _ = io.debug(data_dir())
  io.print("Data Directory (Local): ")
  let _ = io.debug(data_local_dir())
  io.print("Executables Directory: ")
  let _ = io.debug(executable_dir())
  io.print("Preferences Directory: ")
  let _ = io.debug(preference_dir())
  io.print("Runtime Directory: ")
  let _ = io.debug(runtime_dir())
  io.print("State Directory: ")
  let _ = io.debug(state_dir())
}
