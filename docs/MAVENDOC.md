
```
mvn install
mvn javadoc:javadoc
rm -rf docs/mcp-javadoc docs/accessrefinery-javadoc
cp -r accessrefinery/mcp/target/reports/apidocs docs/mcp-javadoc
cp -r accessrefinery/refinery/target/reports/apidocs docs/accessrefinery-javadoc
```
