{
  description = "Static blog generator";
  # nix develop --command gen
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        combinedTemplate = ''
          <html>
          <head>
            <meta charset="UTF-8">
            <title>{{ title }}</title>
            <link rel="stylesheet" href="style.css">
          </head>
          <body>
            <header><h1>My Blog</h1></header>
            <main>
              {{ content }}
            </main>
          </body>
          </html>
        '';

        homeTemplate = ''
          <h2>Blog Posts</h2>
          <ul>
            {{ entries }}
          </ul>
        '';

        postContentTemplate = ''
          <article>
            <h2>{{ title }}</h2>
            <p><em>{{ date }}</em></p>
            {{ body }}
          </article>
        '';

        build = pkgs.writeScriptBin "gen" ''
          #!${pkgs.bash}/bin/bash  
          set -e
          if [ -d output ]; then
              rm -rf output/
          fi
          mkdir -p "output"
          cp style.css "output"
          combined_template='${combinedTemplate}'
          post_content_template='${postContentTemplate}'
          home_template='${homeTemplate}'
          index_entries=""
          for mdfile in ./posts/*.md; do
              filename=$(basename "$mdfile" .md)
              htmlfile="output/$filename.html"
              title=$(grep '^%' "$mdfile" | sed -n '1s/^% *//p')
              date=$(grep '^%' "$mdfile" | sed -n '2s/^% *//p')
              body=$(grep -v '^%' "$mdfile" | ${pkgs.cmark}/bin/cmark)
              post_content="''${post_content_template//\{\{ title \}\}/$title}"
              post_content="''${post_content//\{\{ date \}\}/$date}"
              post_content="''${post_content//\{\{ body \}\}/$body}"
              full_page="''${combined_template//\{\{ title \}\}/$title}"
              full_page="''${full_page//\{\{ content \}\}/$post_content}"
              echo "$full_page" > "$htmlfile"
              echo "Generated $htmlfile"
              index_entries+="<li><a href=\"$filename.html\">$title</a> <small>($date)</small></li>"$'\n'
          done
          home_content="''${home_template//\{\{ entries \}\}/$index_entries}"
          index_page="''${combined_template//\{\{ title \}\}/Home}"
          index_page="''${index_page//\{\{ content \}\}/$home_content}"
          echo "$index_page" > "output/index.html"
          echo "Generated index.html"
          echo "Blog generation complete. Run 'serve' to view it."
        '';
      in
      {
        packages = {
          default = self.packages.${system}.blog;
          
          blog = pkgs.stdenv.mkDerivation {
            name = "static-blog-generator";
            src = ./.;
            
            buildInputs = [
              build
            ];
            
            installPhase = ''
              mkdir -p $out/bin
              ln -s ${build}/bin/gen $out/bin/
            '';
          };
        };
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.cmark
            build
          ];
          shellHook = ''alias serve="python3 -m http.server -d output"'';
        };
      }
    );
}