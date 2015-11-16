package com.isdraw.data
{
	import flash.data.SQLConnection;
	import flash.data.SQLMode;
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	import flash.data.SQLTransactionLockType;
	import flash.events.SQLErrorEvent;
	import flash.events.SQLEvent;
	import flash.filesystem.File;
	import flash.utils.ByteArray;
	import com.isdraw.general.Native;

	public class SQLite
	{
		private var _sqlFile:File;
		private var _conn:SQLConnection;
		
		public function SQLite(sqlFile:*,password:String=null)
		{
			var pass_b:ByteArray;
			if(password!=null){
				pass_b=new ByteArray();
				pass_b.writeUTFBytes(password);
			}
			_sqlFile=Native.resolvePath(sqlFile);
			_conn=new SQLConnection();
			_conn.open(_sqlFile,SQLMode.CREATE,false,1024,pass_b);
		}
		
		/**
		 * 查询所有的元素 
		 * @param sql sql语句
		 * @param param 参数
		 * @return 
		 */		
		public function fetchAll(sql:String,param:Object=null):Array{
			var r:SQLResult=execute(sql,param);
			var list:Array=[];
			if(r!=null){
				list=r.data;
			}
			return list;
		}
		
		/**
		 * 查询所有的元素 
		 */		
		public function fetch(sql:String,param:Object=null):Object{
			var s:SQLStatement=create_statement(sql,param);
			var obj:Object;
			try{
				s.execute(1);
				obj=s.getResult().data[0];
			}catch(e:Error){
				
			}
			return obj;
		}
		
		/**
		 * 更新数据 
		 * @param tablename
		 * @param field
		 * @param param
		 * 
		 */		
		public function update(tablename:String,field:Object,param:Object=null):void{
			if(field==null) return;
			var sql:String=str_format("UPDATE {0} SET {1} WHERE 1=1{2};",this.tablename(tablename),sql_format(field,"{0}=:{0}"),sql_format(param," AND {0}=:{0}",""));
			execute(sql,data_format(field),data_format(param));
		}
		
		/**
		 * 删除数据 
		 * @param tablename
		 * @param param
		 * 
		 */		
		public function remove(tablename:String,param:Object=null):void{
			var sql:String=str_format("DELETE FROM {0} WHERE 1=1{1};",this.tablename(tablename),sql_format(param," AND {0}=:{0}",""));
			execute(sql,data_format(param));
		}
		
		/**
		 * 插入数据库 
		 * @param tablename
		 * @param param
		 * 
		 */		
		public function insert(tablename:String,param:Object):int{
			if(param==null) return 0;
			var kv:Array=sql_collection(param);
			var sql:String=str_format("INSERT INTO {0}({1}) VALUES({2});",this.tablename(tablename),kv[0].join(","),kv[1].join(','));
			
			var r:SQLResult=execute(sql,data_format(param));
			if(r!=null){
				return r.lastInsertRowID;
			}
			return 0;
		}
		
		/**
		 * 创建
		 * @param param
		 * @return 
		 * 
		 */		
		public function sql_format(param:Object,format:String="{0}",joinString:String=","):String{
			var ret:String="";
			if(param!=null){
				var tmp:Array=[];
				for(var j:Object in param){
					tmp.push(str_format(format,j,param[j]));
				}
				ret=tmp.join(joinString);
			}
			return ret;
		}
		
		/**
		 * 参数转换将无:变成带:
		 * @param param 无:的对象
		 * @return 
		 * 
		 */		
		public function data_format(param:Object):Object{
			var p:Object={};
			if(param!=null){
				for(var i:Object in param){
					p[":"+i]=param[i];
				}
			}
			return p;
		}
		
		/**
		 * 表名和内容进行分离 
		 * @return 
		 */		
		private function sql_collection(param:Object):Array{
			var keys:Array=[];
			var values:Array=[];
			for(var i:Object in param){
				keys.push(String(i));
				values.push(":"+String(i));
			}
			return [keys,values];
		}
		
		
		/**
		 * execute 
		 * @param sql
		 */		
		public function execute(sql:String,...args):SQLResult{
			try{
				_conn.begin();
				args.unshift(sql);
				var s:SQLStatement=create_statement.apply(null,args);
				s.execute();
				_conn.commit();
				return s.getResult();
			}catch(e:Error){
				_conn.rollback();
				trace("[SQL ERROR] "+e.message);
			}
			return null;
		}
		
		/**
		 * 获取表名 
		 * @param tablename
		 * @return 
		 */		
		public function tablename(tablename:String):String{
			return "`"+tablename+"`";
		}
		
		/**
		 * 创建执行参数 
		 * @param sql	查询语句
		 * @param param 参数可以为Object或者数组
		 * @return 查询对象
		 */		
		private function create_statement(sql:String,...args):SQLStatement{
			var s:SQLStatement=new SQLStatement();
			s.text=sql;
			s.sqlConnection=_conn;
			for(var i:int=0;i<args.length;i++){
				create_parameters(s,args[i]);
			}
			return s;
		}
		
		/**
		 * 创建查询参数 
		 * @param s	sql语句
		 * @param param
		 * 
		 */		
		private function create_parameters(s:SQLStatement,param:Object):SQLStatement{
			if(param!=null){
				for(var i:Object in param){
					s.parameters[i]=param[i];
				}
			}
			return s;
		}
		
		
		public function get lastInsertid():int{
			return 0;
		}
		
		/**
		 * 格式化字符串
		 * @param	format 字符串格式
		 * @param	...args 参数
		 * @return
		 */
		private function str_format(format:String,...args):String{
			var reg:RegExp =/\{(\d+)\}/img;
			var obj:Object = reg.exec(format);
			var str:String="";
			var lastIndex:int = 0;
			var char:String;
			while (obj != null) {
				str += format.substring(lastIndex, obj.index);
				lastIndex = obj.index+3;
				char = args[int(obj[1])];
				if(!char) char = obj[0];
				str += char;
				obj = reg.exec(format);
			}
			str += format.substring(lastIndex);
			return str;
		}
	}
}