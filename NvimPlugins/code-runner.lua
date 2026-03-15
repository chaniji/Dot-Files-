-- Code Runner Configuration (Nushell + Clang++)
-- Enhanced with Maven and Spring Boot support
-- Optimized with Ayu Dark theme and clean output

return {
  -- Snacks terminal for popup code runner
  {
    "folke/snacks.nvim",
    opts = {
      terminal = {
        win = {
          position = "float",
          border = "rounded",
          width = 0.8,
          height = 0.8,
          style = {
            bg = "#0A0E14",
            fg = "#B3B1Ad",
          },
        },
      },
      styles = {
        terminal = {
          bg = "#0A0E14",
          fg = "#B3B1Ad",
        },
      },
    },
  },

  -- Code Runner with Snacks terminal popup
  {
    "CRAG666/code_runner.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "folke/snacks.nvim",
    },

    cmd = { "RunCode", "RunFile", "RunProject", "RunClose", "RunMaven", "RunSpring" },
    config = function()
      -- Helper function to find pom.xml in current or parent directories
      local function find_pom_xml()
        local current_dir = vim.fn.expand("%:p:h")
        local max_depth = 10

        for _ = 1, max_depth do
          if vim.fn.filereadable(current_dir .. "/pom.xml") == 1 then
            return current_dir
          end

          local parent = vim.fn.fnamemodify(current_dir, ":h")
          if parent == current_dir then
            break
          end
          current_dir = parent
        end

        return nil
      end

      -- Helper function to detect Maven wrapper
      local function has_maven_wrapper()
        local cwd = vim.fn.getcwd()
        return vim.fn.filereadable(cwd .. "/mvnw") == 1
      end

      -- Helper function to get Maven command
      local function get_maven_cmd()
        return has_maven_wrapper() and "./mvnw" or "mvn"
      end

      -- ============================================================
      -- RunCode: Single file runner
      -- ============================================================
      vim.api.nvim_create_user_command("RunCode", function()
        local ft = vim.bo.filetype
        local file = vim.fn.expand("%:p")
        local dir = vim.fn.expand("%:p:h")
        local filename = vim.fn.expand("%:t")
        local filebase = vim.fn.expand("%:t:r")

        local cmd

        -- Java: detect package declaration and resolve source root
        if ft == "java" then
          local package_name = ""
          local ok, lines = pcall(vim.fn.readfile, file)
          if ok then
            for _, line in ipairs(lines) do
              local pkg = line:match("^package%s+([%w%.]+)")
              if pkg then
                package_name = pkg
                break
              end
            end
          end

          if package_name ~= "" then
            -- Walk up one directory per package segment to find source root
            local root = dir
            for _ in package_name:gmatch("[^%.]+") do
              root = vim.fn.fnamemodify(root, ":h")
            end

            cmd = string.format(
              "find '%s' -name '*.java' | xargs javac; java -cp '%s' '%s.%s'; read -rp 'Press Enter to close... '",
              root,
              root,
              package_name,
              filebase
            )
          else
            cmd = string.format(
              "cd '%s'; javac '%s'; java -cp . '%s'; read -rp 'Press Enter to close... '",
              dir,
              filename,
              filebase
            )
          end
        else
          -- All other languages
          local commands = {
            cpp = string.format(
              "cd '%s'; clang++ -std=c++20 -fdiagnostics-color=always '%s' -o '%s'; ./'%s'; input ' Press Enter to close... '",
              dir,
              filename,
              filebase,
              filebase
            ),
            c = string.format(
              "cd '%s'; clang -fdiagnostics-color=always '%s' -o '%s'; ./'%s'; input ' Press Enter to close... '",
              dir,
              filename,
              filebase,
              filebase
            ),
            python = string.format("PYTHONUNBUFFERED=1 python3 -u '%s'; input ' Press Enter to close... '", file),
            javascript = string.format("node '%s'; input ' Press Enter to close... '", file),
            typescript = string.format("ts-node '%s'; input ' Press Enter to close... '", file),
            lua = string.format("lua '%s'; input ' Press Enter to close... '", file),
            sh = string.format("bash '%s'; input ' Press Enter to close... '", file),
            rust = string.format(
              "cd '%s'; rustc '%s' -o '%s'; ./'%s'; input ' Press Enter to close... '",
              dir,
              filename,
              filebase,
              filebase
            ),
            go = string.format("cd '%s'; go run '%s'; input ' Press Enter to close... '", dir, filename),
          }
          cmd = commands[ft]
        end

        if cmd then
          vim.cmd("silent! write")
          require("snacks").terminal(cmd, {
            win = {
              position = "float",
              border = "rounded",
              width = 0.85,
              height = 0.85,
              title = " 󰐊 Running: " .. filename .. " ",
              title_pos = "center",
              style = {
                bg = "#0A0E14",
                fg = "#B3B1Ad",
              },
            },
            env = {
              TERM = "xterm-256color",
              COLORTERM = "truecolor",
              CLICOLOR = "1",
              CLICOLOR_FORCE = "1",
              FORCE_COLOR = "3",
            },
          })
        else
          vim.notify("No runner configured for filetype: " .. ft, vim.log.levels.WARN)
        end
      end, {})

      -- ============================================================
      -- CompileCode: Compile only (check errors)
      -- ============================================================
      vim.api.nvim_create_user_command("CompileCode", function()
        local ft = vim.bo.filetype
        local dir = vim.fn.expand("%:p:h")
        local filename = vim.fn.expand("%:t")
        local filebase = vim.fn.expand("%:t:r")

        local commands = {
          cpp = string.format(
            "cd '%s'; clang++ -std=c++20 -Wall -Wextra -fdiagnostics-color=always '%s' -o '%s'; input ' Press Enter to close... '",
            dir,
            filename,
            filebase
          ),
          c = string.format(
            "cd '%s'; clang -Wall -Wextra -fdiagnostics-color=always '%s' -o '%s'; input ' Press Enter to close... '",
            dir,
            filename,
            filebase
          ),
          java = string.format("cd '%s'; javac '%s'; input ' Press Enter to close... '", dir, filename),
          rust = string.format(
            "cd '%s'; rustc '%s' -o '%s'; input ' Press Enter to close... '",
            dir,
            filename,
            filebase
          ),
        }

        local cmd = commands[ft]
        if cmd then
          vim.cmd("silent! write")
          require("snacks").terminal(cmd, {
            win = {
              position = "float",
              border = "rounded",
              width = 0.7,
              height = 0.5,
              title = "  Compiling: " .. filename .. " ",
              title_pos = "center",
              style = {
                bg = "#0A0E14",
                fg = "#B3B1Ad",
              },
            },
            env = {
              TERM = "xterm-256color",
              COLORTERM = "truecolor",
              CLICOLOR = "1",
              CLICOLOR_FORCE = "1",
              FORCE_COLOR = "3",
            },
          })
        else
          vim.notify("Compile not available for filetype: " .. ft, vim.log.levels.WARN)
        end
      end, {})

      -- ============================================================
      -- RunMaven: Maven project runner
      -- ============================================================
      vim.api.nvim_create_user_command("RunMaven", function()
        local project_dir = find_pom_xml()

        if not project_dir then
          vim.notify(
            "No pom.xml found in current directory or parent directories.\n"
              .. "Make sure you're in a Maven project or use :cd to navigate to your project root.",
            vim.log.levels.ERROR
          )
          return
        end

        vim.cmd("cd " .. project_dir)

        local maven_cmd = get_maven_cmd()

        local pom_content = vim.fn.readfile(project_dir .. "/pom.xml")
        local is_spring_boot = false
        for _, line in ipairs(pom_content) do
          if string.match(line, "spring%-boot") then
            is_spring_boot = true
            break
          end
        end

        local cmd
        if is_spring_boot then
          cmd = string.format(
            "cd '%s'; echo 'Building Spring Boot project...'; %s clean install -DskipTests; echo '\\nStarting Spring Boot application...\\n'; %s spring-boot:run; input '\\n Press Enter to close... '",
            project_dir,
            maven_cmd,
            maven_cmd
          )
        else
          cmd = string.format(
            "cd '%s'; echo 'Building Maven project...'; %s clean compile install -DskipTests; echo '\\nRunning application...\\n'; %s exec:java; input '\\n Press Enter to close... '",
            project_dir,
            maven_cmd,
            maven_cmd
          )
        end

        vim.cmd("silent! wall")

        require("snacks").terminal(cmd, {
          win = {
            position = "float",
            border = "rounded",
            width = 0.9,
            height = 0.9,
            title = is_spring_boot and "  Running: Spring Boot (Maven) " or "  Running: Maven Project ",
            title_pos = "center",
            style = {
              bg = "#0A0E14",
              fg = "#B3B1Ad",
            },
          },
          env = {
            TERM = "xterm-256color",
            COLORTERM = "truecolor",
            CLICOLOR = "1",
            CLICOLOR_FORCE = "1",
            FORCE_COLOR = "3",
            MAVEN_OPTS = "-Xmx2048m",
          },
        })
      end, {})

      -- ============================================================
      -- RunSpring: Spring Boot with DevTools
      -- ============================================================
      vim.api.nvim_create_user_command("RunSpring", function()
        local project_dir = find_pom_xml()

        if not project_dir then
          vim.notify(
            "No pom.xml found in current directory or parent directories.\n"
              .. "Make sure you're in a Maven project or use :cd to navigate to your project root.",
            vim.log.levels.ERROR
          )
          return
        end

        vim.cmd("cd " .. project_dir)

        local maven_cmd = get_maven_cmd()

        local cmd = string.format(
          "cd '%s'; echo 'Starting Spring Boot with DevTools...\\n'; %s spring-boot:run -Dspring-boot.run.jvmArguments='-Dspring.devtools.restart.enabled=true'; input '\\n Press Enter to close... '",
          project_dir,
          maven_cmd
        )

        vim.cmd("silent! wall")

        require("snacks").terminal(cmd, {
          win = {
            position = "float",
            border = "rounded",
            width = 0.9,
            height = 0.9,
            title = " 󱃾 Spring Boot DevTools ",
            title_pos = "center",
            style = {
              bg = "#0A0E14",
              fg = "#B3B1Ad",
            },
          },
          env = {
            TERM = "xterm-256color",
            COLORTERM = "truecolor",
            CLICOLOR = "1",
            CLICOLOR_FORCE = "1",
            FORCE_COLOR = "3",
            MAVEN_OPTS = "-Xmx2048m",
          },
        })
      end, {})

      -- ============================================================
      -- MavenCompile
      -- ============================================================
      vim.api.nvim_create_user_command("MavenCompile", function()
        local project_dir = find_pom_xml()

        if not project_dir then
          vim.notify("No pom.xml found in current directory or parent directories.", vim.log.levels.ERROR)
          return
        end

        vim.cmd("cd " .. project_dir)

        local maven_cmd = get_maven_cmd()
        local cmd = string.format(
          "cd '%s'; echo 'Compiling Maven project...\\n'; %s clean compile; input '\\n Press Enter to close... '",
          project_dir,
          maven_cmd
        )

        vim.cmd("silent! wall")

        require("snacks").terminal(cmd, {
          win = {
            position = "float",
            border = "rounded",
            width = 0.8,
            height = 0.7,
            title = "  Maven Compile ",
            title_pos = "center",
            style = {
              bg = "#0A0E14",
              fg = "#B3B1Ad",
            },
          },
          env = {
            TERM = "xterm-256color",
            COLORTERM = "truecolor",
            CLICOLOR = "1",
            CLICOLOR_FORCE = "1",
            FORCE_COLOR = "3",
          },
        })
      end, {})

      -- ============================================================
      -- MavenClean
      -- ============================================================
      vim.api.nvim_create_user_command("MavenClean", function()
        local project_dir = find_pom_xml()

        if not project_dir then
          vim.notify("No pom.xml found in current directory or parent directories.", vim.log.levels.ERROR)
          return
        end

        vim.cmd("cd " .. project_dir)

        local maven_cmd = get_maven_cmd()
        local cmd = string.format("cd '%s'; %s clean; input ' Press Enter to close... '", project_dir, maven_cmd)

        require("snacks").terminal(cmd, {
          win = {
            position = "float",
            border = "rounded",
            width = 0.6,
            height = 0.5,
            title = "  Maven Clean ",
            title_pos = "center",
            style = {
              bg = "#0A0E14",
              fg = "#B3B1Ad",
            },
          },
        })
      end, {})

      -- ============================================================
      -- MavenTest
      -- ============================================================
      vim.api.nvim_create_user_command("MavenTest", function()
        local project_dir = find_pom_xml()

        if not project_dir then
          vim.notify("No pom.xml found in current directory or parent directories.", vim.log.levels.ERROR)
          return
        end

        vim.cmd("cd " .. project_dir)

        local maven_cmd = get_maven_cmd()
        local cmd = string.format(
          "cd '%s'; echo 'Running tests...\\n'; %s test; input '\\n Press Enter to close... '",
          project_dir,
          maven_cmd
        )

        vim.cmd("silent! wall")

        require("snacks").terminal(cmd, {
          win = {
            position = "float",
            border = "rounded",
            width = 0.85,
            height = 0.85,
            title = "  Maven Test ",
            title_pos = "center",
            style = {
              bg = "#0A0E14",
              fg = "#B3B1Ad",
            },
          },
          env = {
            TERM = "xterm-256color",
            COLORTERM = "truecolor",
            CLICOLOR = "1",
            CLICOLOR_FORCE = "1",
            FORCE_COLOR = "3",
          },
        })
      end, {})

      -- ============================================================
      -- MavenStop
      -- ============================================================
      vim.api.nvim_create_user_command("MavenStop", function()
        local cmd =
          "pkill -f 'spring-boot:run'; pkill -f 'mvn'; pkill -f 'maven'; pkill -f 'java'; echo 'Stopped all Maven/Java processes'; input ' Press Enter to close... '"

        require("snacks").terminal(cmd, {
          win = {
            position = "float",
            border = "rounded",
            width = 0.6,
            height = 0.4,
            title = "  Stopping Maven/Java ",
            title_pos = "center",
            style = {
              bg = "#0A0E14",
              fg = "#B3B1Ad",
            },
          },
        })
      end, {})

      -- ============================================================
      -- SpringStop
      -- ============================================================
      vim.api.nvim_create_user_command("SpringStop", function()
        local cmd = [[
          echo '=== Stopping Spring Boot Server ==='
          echo ''
          lsof -ti:8080 2>/dev/null | xargs kill -9 2>/dev/null; echo '✓ Killed process on port 8080'
          lsof -ti:8081 2>/dev/null | xargs kill -9 2>/dev/null; echo '✓ Killed process on port 8081'
          lsof -ti:9090 2>/dev/null | xargs kill -9 2>/dev/null; echo '✓ Killed process on port 9090'
          pkill -f 'spring-boot:run' 2>/dev/null; echo '✓ Killed remaining spring-boot processes'
          echo ''
          echo 'Spring Boot server stopped'
          input ' Press Enter to close... '
        ]]

        require("snacks").terminal(cmd, {
          win = {
            position = "float",
            border = "rounded",
            width = 0.7,
            height = 0.6,
            title = " 󱃾 Stopping Spring Boot ",
            title_pos = "center",
            style = {
              bg = "#0A0E14",
              fg = "#B3B1Ad",
            },
          },
        })
      end, {})

      -- ============================================================
      -- StopAll
      -- ============================================================
      vim.api.nvim_create_user_command("StopAll", function()
        local cmd = [[
          echo '╔════════════════════════════════════════╗'
          echo '║   STOPPING ALL RUNNING PROJECTS        ║'
          echo '╚════════════════════════════════════════╝'
          echo ''
          echo '🔴 Stopping Maven/Spring Boot...'
          pkill -f 'spring-boot:run' 2>/dev/null; echo '  ✓ Spring Boot processes killed'
          pkill -f 'mvn' 2>/dev/null; echo '  ✓ Maven processes killed'
          pkill -f 'maven' 2>/dev/null
          echo '🔴 Stopping npm/Vite/Node...'
          pkill -f 'npm' 2>/dev/null; echo '  ✓ npm processes killed'
          pkill -f 'vite' 2>/dev/null; echo '  ✓ Vite killed'
          pkill -f 'node' 2>/dev/null; echo '  ✓ Node processes killed'
          echo '🔴 Stopping servers on common ports...'
          lsof -ti:3000 2>/dev/null | xargs kill -9 2>/dev/null; echo '  ✓ Port 3000 cleared'
          lsof -ti:3001 2>/dev/null | xargs kill -9 2>/dev/null; echo '  ✓ Port 3001 cleared'
          lsof -ti:5173 2>/dev/null | xargs kill -9 2>/dev/null; echo '  ✓ Port 5173 cleared'
          lsof -ti:5174 2>/dev/null | xargs kill -9 2>/dev/null; echo '  ✓ Port 5174 cleared'
          lsof -ti:8080 2>/dev/null | xargs kill -9 2>/dev/null; echo '  ✓ Port 8080 cleared'
          lsof -ti:8081 2>/dev/null | xargs kill -9 2>/dev/null; echo '  ✓ Port 8081 cleared'
          lsof -ti:9090 2>/dev/null | xargs kill -9 2>/dev/null; echo '  ✓ Port 9090 cleared'
          lsof -ti:4200 2>/dev/null | xargs kill -9 2>/dev/null; echo '  ✓ Port 4200 cleared'
          echo '🔴 Stopping Cargo/Rust...'
          pkill -f 'cargo' 2>/dev/null; echo '  ✓ Cargo killed'
          echo '🔴 Stopping Gradle...'
          pkill -f 'gradle' 2>/dev/null; echo '  ✓ Gradle killed'
          echo '🔴 Stopping Java processes...'
          pkill -f 'java' 2>/dev/null; echo '  ✓ Java processes killed'
          echo ''
          echo '✅ All development servers and projects stopped!'
          echo ''
          input ' Press Enter to close... '
        ]]

        require("snacks").terminal(cmd, {
          win = {
            position = "float",
            border = "rounded",
            width = 0.8,
            height = 0.8,
            title = " 🛑 STOP ALL PROJECTS ",
            title_pos = "center",
            style = {
              bg = "#0A0E14",
              fg = "#B3B1Ad",
            },
          },
        })
      end, {})

      -- ============================================================
      -- MavenStatus
      -- ============================================================
      vim.api.nvim_create_user_command("MavenStatus", function()
        local cmd =
          "echo '=== Running Maven/Java Processes ===\\n'; ps aux | grep -E 'maven|mvn|spring-boot' | grep -v grep; echo '\\n'; ps aux | grep java | grep -v grep; input '\\n Press Enter to close... '"

        require("snacks").terminal(cmd, {
          win = {
            position = "float",
            border = "rounded",
            width = 0.9,
            height = 0.7,
            title = "  Maven/Java Processes ",
            title_pos = "center",
            style = {
              bg = "#0A0E14",
              fg = "#B3B1Ad",
            },
          },
        })
      end, {})

      -- ============================================================
      -- RunProject
      -- ============================================================
      vim.api.nvim_create_user_command("RunProject", function()
        local dir = vim.fn.getcwd()
        local cmd = nil
        local title = ""

        if vim.fn.filereadable(dir .. "/pom.xml") == 1 then
          vim.cmd("RunMaven")
          return
        elseif vim.fn.filereadable(dir .. "/package.json") == 1 then
          cmd = "cd '" .. dir .. "'; npm run dev; input ' Press Enter to close... '"
          title = " 󰎙 Running: npm run dev "
        elseif vim.fn.filereadable(dir .. "/Cargo.toml") == 1 then
          cmd = "cd '" .. dir .. "'; cargo run; input ' Press Enter to close... '"
          title = " 🦀 Running: cargo run "
        elseif vim.fn.filereadable(dir .. "/build.gradle") == 1 then
          cmd = "cd '" .. dir .. "'; ./gradlew build; ./gradlew run; input ' Press Enter to close... '"
          title = "  Running: Gradle Project "
        elseif vim.fn.filereadable(dir .. "/Makefile") == 1 then
          cmd = "cd '" .. dir .. "'; make run; input ' Press Enter to close... '"
          title = "  Running: make run "
        end

        if cmd then
          vim.cmd("silent! wall")
          require("snacks").terminal(cmd, {
            win = {
              position = "float",
              border = "rounded",
              width = 0.9,
              height = 0.9,
              title = title,
              title_pos = "center",
              style = {
                bg = "#0A0E14",
                fg = "#B3B1Ad",
              },
            },
            env = {
              TERM = "xterm-256color",
              COLORTERM = "truecolor",
              CLICOLOR = "1",
              CLICOLOR_FORCE = "1",
              FORCE_COLOR = "3",
            },
          })
        else
          vim.notify(
            "No project configuration found\n(package.json, Cargo.toml, pom.xml, build.gradle, or Makefile)",
            vim.log.levels.WARN
          )
        end
      end, {})
    end,

    -- Keybindings
    keys = {
      { "<leader>r", "<cmd>RunCode<cr>", desc = "Run Code" },
      { "<leader>rc", "<cmd>CompileCode<cr>", desc = "Compile Code" },
      { "<leader>rp", "<cmd>RunProject<cr>", desc = "Run Project" },
      { "<leader>rm", "<cmd>RunMaven<cr>", desc = "Run Maven Project" },
      { "<leader>rs", "<cmd>RunSpring<cr>", desc = "Run Spring Boot" },
      { "<leader>rss", "<cmd>SpringStop<cr>", desc = "Stop Spring Boot Server" },
      { "<leader>rmc", "<cmd>MavenCompile<cr>", desc = "Maven Compile" },
      { "<leader>rmt", "<cmd>MavenTest<cr>", desc = "Maven Test" },
      { "<leader>rmC", "<cmd>MavenClean<cr>", desc = "Maven Clean" },
      { "<leader>rms", "<cmd>MavenStop<cr>", desc = "Stop Maven/Java" },
      { "<leader>rmS", "<cmd>MavenStatus<cr>", desc = "Maven Status" },
      { "<leader>rX", "<cmd>StopAll<cr>", desc = "🛑 STOP ALL PROJECTS" },
    },
  },
}
