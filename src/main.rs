use anyhow::{Context, Result};
use clap::{Parser, Subcommand};
use std::path::PathBuf;
use std::process::Command;
use which::which;
use std::env;

#[derive(Parser)]
#[command(author, version, about, long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Create a new virtual environment
    Create {
        /// Name of the virtual environment
        #[arg(short, long)]
        name: String,
        /// Python version to use
        #[arg(short, long)]
        python: String,
    },
    /// Remove a virtual environment
    Remove {
        /// Name of the virtual environment
        #[arg(short, long)]
        name: String,
    },
    /// List all virtual environments
    List,
    /// Activate a virtual environment
    Activate {
        /// Name of the virtual environment
        name: String,
    },
    /// Deactivate the current virtual environment
    Deactivate,
    /// Install packages in the current virtual environment
    Install {
        /// Packages to install
        packages: Vec<String>,
    },
    /// Uninstall packages from the current virtual environment
    Uninstall {
        /// Packages to uninstall
        packages: Vec<String>,
    },
    /// Configure vuv settings
    Config {
        /// Set default index URL
        #[arg(long)]
        default_index: Option<String>,
    },
}

#[cfg(target_os = "windows")]
use std::os::windows::process::CommandExt;

struct VuvConfig {
    venv_dir: PathBuf,
    config_dir: PathBuf,
    config_file: PathBuf,
}

impl VuvConfig {
    fn new() -> Result<Self> {
        // 首先检查环境变量中是否有自定义目录
        let venv_dir = if let Ok(dir) = env::var("VUV_VENV_DIR") {
            PathBuf::from(dir)
        } else {
            let base_dir = if cfg!(windows) {
                PathBuf::from(env::var("APPDATA").context("Could not find APPDATA directory")?)
            } else {
                dirs::home_dir().context("Could not find home directory")?
            };
            base_dir.join(".venvs")
        };

        let config_dir = if let Ok(dir) = env::var("VUV_CONFIG_DIR") {
            PathBuf::from(dir)
        } else {
            let base_dir = if cfg!(windows) {
                PathBuf::from(env::var("APPDATA").context("Could not find APPDATA directory")?)
            } else {
                dirs::home_dir().context("Could not find home directory")?
            };
            base_dir.join(".vuv")
        };

        Ok(Self {
            venv_dir,
            config_dir: config_dir.clone(),
            config_file: config_dir.join("vuv_config"),
        })
    }

    fn ensure_dirs_exist(&self) -> Result<()> {
        std::fs::create_dir_all(&self.venv_dir)?;
        std::fs::create_dir_all(&self.config_dir)?;
        Ok(())
    }

    fn write_config(&self, key: &str, value: &str) -> Result<()> {
        let config_content = if cfg!(windows) {
            format!("$env:{}=\"{}\"", key, value)
        } else {
            format!("export {}={}", key, value)
        };
        std::fs::write(&self.config_file, config_content)?;
        Ok(())
    }
}

fn check_uv_installed() -> Result<()> {
    let uv_name = if cfg!(windows) { "uv.exe" } else { "uv" };
    which(uv_name).context("uv is not installed")?;
    Ok(())
}

fn create_venv(config: &VuvConfig, name: &str, python: &str) -> Result<()> {
    let venv_path = config.venv_dir.join(name);
    if venv_path.exists() {
        anyhow::bail!("Virtual environment {} already exists", name);
    }

    let mut cmd = Command::new("uv");
    cmd.args(["venv", &venv_path.to_string_lossy(), "--python", python]);

    #[cfg(target_os = "windows")]
    {
        use std::os::windows::process::CommandExt;
        cmd.creation_flags(0x08000000); // CREATE_NO_WINDOW
    }

    cmd.status().context("Failed to create virtual environment")?;

    println!("Created virtual environment: {}", name);
    println!("To activate, run: vuv activate {}", name);
    Ok(())
}

fn remove_venv(config: &VuvConfig, name: &str) -> Result<()> {
    let venv_path = config.venv_dir.join(name);
    if !venv_path.exists() {
        anyhow::bail!("Virtual environment {} does not exist", name);
    }

    std::fs::remove_dir_all(&venv_path)?;
    println!("Removed virtual environment: {}", name);
    Ok(())
}

fn list_venvs(config: &VuvConfig) -> Result<()> {
    println!("Virtual environments directory: {}", config.venv_dir.display());
    
    let entries = std::fs::read_dir(&config.venv_dir)?;
    let mut found = false;
    
    for entry in entries {
        found = true;
        let entry = entry?;
        println!("  {}", entry.file_name().to_string_lossy());
    }

    if !found {
        println!("No virtual environments found");
    }
    
    Ok(())
}

fn print_config_info(config: &VuvConfig) -> Result<()> {
    println!("\nCurrent configuration:");
    println!("Virtual environments directory: {}", config.venv_dir.display());
    println!("Configuration directory: {}", config.config_dir.display());
    println!("\nTo customize these locations, set these environment variables:");
    println!("VUV_VENV_DIR  - Directory for virtual environments");
    println!("VUV_CONFIG_DIR - Directory for vuv configuration");
    Ok(())
}


fn run_pip_command(packages: &[String], install: bool) -> Result<()> {
    if env::var("VIRTUAL_ENV").is_err() {
        anyhow::bail!("No virtual environment is currently activated. Please activate one first.");
    }

    let mut cmd = Command::new("uv");
    cmd.args(["pip"]);
    
    if install {
        cmd.arg("install");
    } else {
        cmd.arg("uninstall");
    }
    
    cmd.args(packages);

    #[cfg(target_os = "windows")]
    {
        use std::os::windows::process::CommandExt;
        cmd.creation_flags(0x08000000); // CREATE_NO_WINDOW
    }

    cmd.status().context(if install {
        "Failed to install packages"
    } else {
        "Failed to uninstall packages"
    })?;
    
    Ok(())
}

fn main() -> Result<()> {
    let cli = Cli::parse();
    let config = VuvConfig::new()?;
    config.ensure_dirs_exist()?;
    check_uv_installed()?;

    match cli.command {
        Commands::Create { name, python } => {
            let result = create_venv(&config, &name, &python);
            print_config_info(&config)?;
            result
        },
        Commands::Remove { name } => remove_venv(&config, &name),
        Commands::List => {
            list_venvs(&config)?;
            print_config_info(&config)
        },
        Commands::Activate { name: _ } => {
            println!("Note: This command must be run through the shell function.");
            println!("If you're seeing this message, it means you're running the binary directly.");
            println!("Please make sure you've properly installed vuv using the install script.");
            Ok(())
        },
        Commands::Deactivate => {
            println!("Note: This command must be run through the shell function.");
            println!("If you're seeing this message, it means you're running the binary directly.");
            println!("Please make sure you've properly installed vuv using the install script.");
            Ok(())
        },
        Commands::Install { packages } => run_pip_command(&packages, true),
        Commands::Uninstall { packages } => run_pip_command(&packages, false),
        Commands::Config { default_index } => {
            if let Some(index) = default_index {
                config.write_config("DEFAULT_INDEX", &index)?;
                println!("Default index set to: {}", index);
            }
            Ok(())
        },
    }
}
