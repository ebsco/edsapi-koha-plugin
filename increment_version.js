const jsonfile = require('jsonfile')
const file = 'package.json'
 
let json = jsonfile.readFileSync(file);

console.log("Version: " + json.version );
console.log("Previous Version: " + json.previous_version );

const version = json.version;
const version_parts = version.split('.');
let major = parseInt( version_parts[0] );
let minor = parseInt( version_parts[1] );
let patch = parseInt( version_parts[2] );

const prev_version = json.previous_version;
const prev_version_parts = prev_version.split('.');
let prev_major = parseInt( version_parts[0] );
let prev_minor = parseInt( version_parts[1] );
let prev_patch = parseInt( version_parts[2] );

let new_version;

// No version jumps, just increment patch version
if ( major == prev_major && minor == prev_minor ) {
    prev_major = major;
    prev_minor = minor;
    prev_patch = patch;

    patch++;

    new_version = major + '.' + minor + '.' + patch;
} else { // Version jumped, don't increment patch
    new_version = version;     
}

json.previous_version = version;
json.version = new_version;

jsonfile.writeFile(file, json, {spaces: 2}, function (err) {
  if (err) console.error("ERROR: " + err);
})

console.log("New Version: " + json.version );
console.log("New Previous Version: " + json.previous_version );
