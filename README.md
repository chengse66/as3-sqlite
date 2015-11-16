SQLITE FOR AIR DIRVER

----------
[http://isdraw.com](http://isdraw.com)

useage:

	var sql:SQLite=new SQLite("sample.db");
	
	//insert return lastInsertId
	sql.insert("user",{user_text:"helloworld"});
	
	//remove
	sql.remove("user",{user_id:13});
	
	//update
	sql.update("user",{user_text:"helloworld user!"},{user_id:13});
	
	//fetchAll return Array
	sql.fetchAll("select * from user where user_id>:id;",{":id":2});
	
	//fetch return object
	sql.fetch("select * from user where user_id>:id;",{":id":2});

更多问题请邮件我:nease@163.com