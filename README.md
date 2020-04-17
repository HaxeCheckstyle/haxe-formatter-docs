## How to build site

```bash
git clone https://github.com/HaxeCheckstyle/haxe-formatter-docs
npm i
npx lix download
mkdir -p docs/samples/lineends
mkdir -p site/css
mkdir -p site/js
npx haxe build.hxml
npx npx sass css/formatter-docs.scss site/css/formatter-docs.css
cp node_modules/jquery/dist/jquery.min.js site/js/

cd site
php -S localhost:8080     # or use some other improtu webserver for local testing
```

point browser at http://localhost:8080
