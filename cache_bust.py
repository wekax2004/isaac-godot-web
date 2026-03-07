import os
import time
import re

html_path = 'build/web/index.html'

if not os.path.exists(html_path):
    print("Error: index.html not found at", html_path)
    exit(1)

with open(html_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Generate a timestamp query string
ts = str(int(time.time()))
query = '?v=' + ts

# WebAssembly instantiation in Godot 4 HTML exports usually happens via the generated .js file, but Godot 4's HTML shell handles passing the args.
# In Godot 4.2+, the engine loads the .wasm and .pck based on the `executableName`.
# The most robust way to cachebust is to hook the fetch() or Godot Engine config in the HTML.
# Look for the engine initialization snippet:
# const engine = new Engine(engineConfig);

# We'll inject a service worker bypass or update the args.
# Alternatively, a very simple way is to rename the executable or add args to the engine config.

cache_bust_script = f"""
		// Inject Cache-Busting
		const ogFetch = window.fetch;
		window.fetch = function() {{
			let args = arguments;
			if (typeof args[0] === 'string' && (args[0].endsWith('.wasm') || args[0].endsWith('.pck') || args[0].endsWith('.js'))) {{
				args[0] = args[0] + '{query}';
			}}
			return ogFetch.apply(this, args);
		}};
"""

if "// Inject Cache-Busting" not in content:
    # Inject right before the script tag that loads the engine
    content = content.replace('const engine = new Engine(engineConfig);', cache_bust_script + '\n\t\tconst engine = new Engine(engineConfig);')
    
    with open(html_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Successfully injected cache-busting fetch override into index.html")
else:
    print("Cache-busting script already present.")
