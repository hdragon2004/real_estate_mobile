import React, { useEffect, useState } from 'react';
import { Layout, Table, Tag, Space, Button, Modal, Descriptions } from 'antd';
import Sidebar from '../../components/Sidebar';
import axiosPrivate from '../../api/axiosPrivate';
import { unwrapListResponse } from '../../api/responseHelper';
import MessageProvider from '../../components/MessageProvider';

const { Content } = Layout;

const MessagesPage = () => {
  const [messages, setMessages] = useState([]);
  const [loading, setLoading] = useState(true);
  const [detail, setDetail] = useState(null);
  const { showMessage, contextHolder } = MessageProvider();

  useEffect(() => {
    fetchMessages();
  }, []);

  const fetchMessages = async () => {
      try {
        const res = await axiosPrivate.get('/api/admin/messages');
        const messagesData = unwrapListResponse(res);
        setMessages(messagesData);
      } catch (error) {
        console.error('Error fetching messages:', error);
        const errorData = error.response?.data;
        const errorMessage = errorData?.message || errorData || 'Không thể tải danh sách tin nhắn';
        showMessage.error(errorMessage);
      } finally {
        setLoading(false);
      }
  };

  const handleDelete = async (id) => {
    if (window.confirm('Bạn có chắc chắn muốn xóa tin nhắn này?')) {
      try {
        // Note: Cần thêm endpoint DELETE /api/admin/messages/{id} nếu cần
        showMessage.info('Chức năng xóa tin nhắn đang được phát triển');
      } catch (error) {
        console.error('Error deleting message:', error);
        const errorMessage = error.response?.data?.message || error.response?.data || 'Không thể xóa tin nhắn';
        showMessage.error(errorMessage);
      }
    }
  };

  const columns = [
    { 
      title: 'ID', 
      dataIndex: 'id', 
      key: 'id', 
      width: 80 
    },
    { 
      title: 'Người gửi', 
      dataIndex: 'senderName', 
      key: 'senderName',
      render: (text, record) => (
        <span style={{ color: '#fff' }}>
          {text || `User ID: ${record.senderId}`}
        </span>
      )
    },
    { 
      title: 'Người nhận', 
      dataIndex: 'receiverName', 
      key: 'receiverName',
      render: (text, record) => (
        <span style={{ color: '#fff' }}>
          {text || `User ID: ${record.receiverId}`}
        </span>
      )
    },
    { 
      title: 'Bài viết', 
      dataIndex: 'postTitle', 
      key: 'postTitle',
      ellipsis: true,
      render: (text, record) => (
        <span style={{ color: '#fff' }}>
          {text || `Post ID: ${record.postId || 'N/A'}`}
        </span>
      )
    },
    { 
      title: 'Nội dung', 
      dataIndex: 'content', 
      key: 'content',
      ellipsis: true,
      render: (text) => <span style={{ color: '#fff' }}>{text}</span>
    },
    { 
      title: 'Trạng thái', 
      dataIndex: 'isRead', 
      key: 'isRead',
      render: (isRead) => (
        <Tag color={isRead ? 'green' : 'orange'}>
          {isRead ? 'Đã đọc' : 'Chưa đọc'}
        </Tag>
      )
    },
    { 
      title: 'Thời gian', 
      dataIndex: 'sentTime', 
      key: 'sentTime',
      render: (date) => (
        <span style={{ color: '#fff' }}>
          {date ? new Date(date).toLocaleString('vi-VN') : 'N/A'}
        </span>
      )
    },
    {
      title: 'Hành động',
      key: 'action',
      width: 120,
      render: (_, record) => (
        <Space>
          <Button onClick={() => setDetail(record)}>Xem</Button>
        </Space>
      ),
    },
  ];

  return (
    <Layout style={{ minHeight: '100vh' }}>
      {contextHolder}
      <Sidebar selectedKey="/admin/messages" />
      <Layout>
        <Content style={{ margin: '24px 16px 0', background: '#141414' }}>
          <h1 style={{ color: '#fff', fontSize: 24, fontWeight: 700 }}>Quản lý tin nhắn</h1>
          <Table 
            columns={columns} 
            dataSource={messages} 
            loading={loading} 
            rowKey="id" 
            style={{ marginTop: 24 }}
            pagination={{ pageSize: 20 }}
          />
          <Modal 
            open={!!detail} 
            onCancel={() => setDetail(null)} 
            footer={null} 
            title="Chi tiết tin nhắn"
            width={600}
          >
            {detail && (
              <Descriptions bordered column={1} size="small">
                <Descriptions.Item label="ID">{detail.id}</Descriptions.Item>
                <Descriptions.Item label="Người gửi">
                  {detail.senderName || `User ID: ${detail.senderId}`}
                </Descriptions.Item>
                <Descriptions.Item label="Người nhận">
                  {detail.receiverName || `User ID: ${detail.receiverId}`}
                </Descriptions.Item>
                <Descriptions.Item label="Bài viết">
                  {detail.postTitle || `Post ID: ${detail.postId || 'N/A'}`}
                </Descriptions.Item>
                <Descriptions.Item label="Nội dung">{detail.content}</Descriptions.Item>
                <Descriptions.Item label="Trạng thái">
                  <Tag color={detail.isRead ? 'green' : 'orange'}>
                    {detail.isRead ? 'Đã đọc' : 'Chưa đọc'}
                  </Tag>
                </Descriptions.Item>
                <Descriptions.Item label="Thời gian">
                  {detail.sentTime ? new Date(detail.sentTime).toLocaleString('vi-VN') : 'N/A'}
                </Descriptions.Item>
              </Descriptions>
            )}
          </Modal>
        </Content>
      </Layout>
    </Layout>
  );
};

export default MessagesPage;

